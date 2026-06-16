import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lull/data/local/app_database.dart';
import 'package:lull/features/essentials/data/essentials_repository.dart';
import 'package:lull/features/essentials/data/local_first_essentials_repository.dart';
import 'package:lull/features/essentials/domain/essential.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

import '../../support/fake_essentials_repository.dart';

/// Wraps a fake remote with an on/off switch so a test can drop the network
/// mid-flow and bring it back. Offline, every call fails like Supabase would.
/// Ids in [rejectCreateIds] are rejected with a PostgrestException (a permanent,
/// server-reached failure — i.e. a poison entry).
class _ToggleRemote implements EssentialsRepository {
  _ToggleRemote(this._inner);

  final EssentialsRepository _inner;
  bool online = true;
  final Set<String> rejectCreateIds = <String>{};

  Future<T> _guard<T>(Future<T> Function() op) async {
    if (!online) throw Exception('offline');
    return op();
  }

  @override
  Future<List<Essential>> fetchToday() => _guard(_inner.fetchToday);

  @override
  Future<void> create({
    required String id,
    required int slot,
    required String title,
    required int targetPomodoros,
  }) async {
    if (!online) throw Exception('offline');
    if (rejectCreateIds.contains(id)) {
      throw const PostgrestException(message: 'duplicate slot', code: '23505');
    }
    return _inner.create(
      id: id,
      slot: slot,
      title: title,
      targetPomodoros: targetPomodoros,
    );
  }

  @override
  Future<void> update({
    required String id,
    required String title,
    required int targetPomodoros,
  }) => _guard(
    () => _inner.update(id: id, title: title, targetPomodoros: targetPomodoros),
  );

  @override
  Future<void> setCompleted({required String id, required bool done}) =>
      _guard(() => _inner.setCompleted(id: id, done: done));

  @override
  Future<void> delete(String id) => _guard(() => _inner.delete(id));
}

void main() {
  late AppDatabase db;
  late FakeEssentialsRepository server;
  late _ToggleRemote remote;
  late LocalFirstEssentialsRepository repo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    server = FakeEssentialsRepository();
    remote = _ToggleRemote(server);
    repo = LocalFirstEssentialsRepository(remote, db);
  });

  tearDown(() async => db.close());

  test('online create writes through to the server and the cache', () async {
    await repo.create(id: 'a', slot: 1, title: 'draft', targetPomodoros: 2);

    expect(await db.outboxIsEmpty(), isTrue, reason: 'flushed immediately');
    final onServer = await server.fetchToday();
    expect(onServer.single.id, 'a');

    final visible = await repo.fetchToday();
    expect(visible.single.title, 'draft');
  });

  test('offline create stays in the cache and queues for later', () async {
    remote.online = false;

    await repo.create(id: 'a', slot: 1, title: 'offline task', targetPomodoros: 1);

    // The UI still sees it...
    final visible = await repo.fetchToday();
    expect(visible.single.title, 'offline task');
    // ...and it's queued, not on the server yet.
    expect(await db.outboxIsEmpty(), isFalse);
  });

  test('reconnect drains the queue to the server in order', () async {
    remote.online = false;
    await repo.create(id: 'a', slot: 1, title: 'first', targetPomodoros: 1);
    await repo.update(id: 'a', title: 'renamed', targetPomodoros: 3);
    await repo.setCompleted(id: 'a', done: true);

    expect(await db.outboxIsEmpty(), isFalse);

    remote.online = true;
    final visible = await repo.fetchToday(); // triggers the drain

    expect(await db.outboxIsEmpty(), isTrue, reason: 'queue replayed');
    final onServer = await server.fetchToday();
    expect(onServer.single.title, 'renamed');
    expect(onServer.single.targetPomodoros, 3);
    expect(onServer.single.complete, isTrue);
    // The reconciled view matches the server.
    expect(visible.single.complete, isTrue);
  });

  test('offline delete removes locally and replays on reconnect', () async {
    await repo.create(id: 'a', slot: 1, title: 'temp', targetPomodoros: 1);
    expect((await server.fetchToday()).length, 1);

    remote.online = false;
    await repo.delete('a');
    expect((await repo.fetchToday()).isEmpty, isTrue, reason: 'gone locally');

    remote.online = true;
    await repo.fetchToday(); // drains the delete
    expect((await server.fetchToday()).isEmpty, isTrue, reason: 'gone on server');
  });

  test('server is the source of truth once the queue is empty', () async {
    // A row created elsewhere shows up after a refresh.
    await server.create(id: 'z', slot: 2, title: 'from another device', targetPomodoros: 1);

    final visible = await repo.fetchToday();
    expect(visible.single.id, 'z');
  });

  test('a server-rejected entry is dropped so the queue keeps flowing', () async {
    remote.online = false;
    await repo.create(id: 'poison', slot: 1, title: 'dup', targetPomodoros: 1);
    await repo.create(id: 'good', slot: 2, title: 'ok', targetPomodoros: 1);

    // Back online, but the server permanently rejects 'poison'.
    remote.rejectCreateIds.add('poison');
    remote.online = true;
    await repo.fetchToday(); // drains

    expect(
      await db.outboxIsEmpty(),
      isTrue,
      reason: 'poison dropped, good applied',
    );
    final ids = (await server.fetchToday()).map((e) => e.id);
    expect(ids, contains('good'));
    expect(ids, isNot(contains('poison')));
  });

  test('offline create then delete of the same row cancels out', () async {
    remote.online = false;
    await repo.create(id: 'temp', slot: 1, title: 'temp', targetPomodoros: 1);
    await repo.delete('temp');

    remote.online = true;
    await repo.fetchToday(); // coalesce drops both — no server calls

    expect(await db.outboxIsEmpty(), isTrue);
    expect((await server.fetchToday()).isEmpty, isTrue);
  });
}
