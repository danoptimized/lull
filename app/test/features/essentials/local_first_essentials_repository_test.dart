import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lull/data/local/app_database.dart';
import 'package:lull/features/essentials/data/essentials_repository.dart';
import 'package:lull/features/essentials/data/local_first_essentials_repository.dart';
import 'package:lull/features/essentials/domain/essential.dart';

import '../../support/fake_essentials_repository.dart';

/// Wraps a fake remote with an on/off switch so a test can drop the network
/// mid-flow and bring it back. Offline, every call fails like Supabase would.
class _ToggleRemote implements EssentialsRepository {
  _ToggleRemote(this._inner);

  final EssentialsRepository _inner;
  bool online = true;

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
  }) => _guard(
    () => _inner.create(
      id: id,
      slot: slot,
      title: title,
      targetPomodoros: targetPomodoros,
    ),
  );

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
}
