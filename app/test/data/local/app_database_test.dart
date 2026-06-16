import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lull/data/local/app_database.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() async => db.close());

  CachedEssentialsCompanion ess(
    String id,
    String date,
    int slot, {
    String title = 't',
    int target = 1,
  }) => CachedEssentialsCompanion.insert(
    id: id,
    localDate: date,
    slot: slot,
    title: title,
    targetPomodoros: target,
  );

  test('essentialsForDate returns only that day, sorted by slot', () async {
    await db.upsertEssential(ess('b', '2026-06-16', 3));
    await db.upsertEssential(ess('a', '2026-06-16', 1));
    await db.upsertEssential(ess('y', '2026-06-15', 2)); // another day

    final today = await db.essentialsForDate('2026-06-16');
    expect(today.map((e) => e.id), ['a', 'b'], reason: 'sorted by slot');
  });

  test('upsertEssential updates the row on an id conflict', () async {
    await db.upsertEssential(ess('a', '2026-06-16', 1, title: 'first'));
    await db.upsertEssential(ess('a', '2026-06-16', 1, title: 'second'));

    final rows = await db.essentialsForDate('2026-06-16');
    expect(rows.single.title, 'second');
  });

  test('replaceEssentialsForDate swaps only the target day', () async {
    await db.upsertEssential(ess('y', '2026-06-15', 1));
    await db.upsertEssential(ess('old', '2026-06-16', 1));

    await db.replaceEssentialsForDate('2026-06-16', [ess('new', '2026-06-16', 2)]);

    expect((await db.essentialsForDate('2026-06-16')).map((e) => e.id), ['new']);
    expect(
      (await db.essentialsForDate('2026-06-15')).map((e) => e.id),
      ['y'],
      reason: 'other days untouched',
    );
  });

  test('outbox is FIFO by seq and drains to empty', () async {
    expect(await db.outboxIsEmpty(), isTrue);

    await db.enqueue(
      OutboxEntriesCompanion.insert(
        opId: 'o1',
        kind: 'create',
        essentialId: 'a',
        createdAt: DateTime(2026),
      ),
    );
    await db.enqueue(
      OutboxEntriesCompanion.insert(
        opId: 'o2',
        kind: 'delete',
        essentialId: 'a',
        createdAt: DateTime(2026),
      ),
    );

    final pending = await db.pendingOutbox();
    expect(pending.map((e) => e.opId), ['o1', 'o2'], reason: 'oldest first');
    expect(await db.outboxIsEmpty(), isFalse);

    await db.deleteOutboxEntry(pending.first.seq);
    expect((await db.pendingOutbox()).single.opId, 'o2');

    await db.deleteOutboxEntry(pending.last.seq);
    expect(await db.outboxIsEmpty(), isTrue);
  });
}
