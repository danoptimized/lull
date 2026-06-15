import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

part 'app_database.g.dart';

/// A local mirror of today's `daily_essentials` rows. Supabase stays the source
/// of truth; this is a cache the UI can read instantly and offline. Rows are
/// keyed by the same uuid the server uses (the client mints it), so there is no
/// local↔server id remapping.
@DataClassName('CachedEssential')
class CachedEssentials extends Table {
  TextColumn get id => text()();
  TextColumn get localDate => text()(); // yyyy-MM-dd, matches server local_date
  IntColumn get slot => integer()();
  TextColumn get title => text()();
  IntColumn get targetPomodoros => integer()();
  IntColumn get completedPomodoros => integer().withDefault(const Constant(0))();
  DateTimeColumn get completedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// A durable queue of essentials mutations made locally, replayed against
/// Supabase in `seq` order when connectivity returns. Each entry is the intent
/// of one mutation; replaying the queue in order reproduces the user's edits on
/// the server (last write wins per field).
@DataClassName('OutboxEntry')
class OutboxEntries extends Table {
  IntColumn get seq => integer().autoIncrement()();
  TextColumn get opId => text()(); // client uuid, for traceability/dedupe
  TextColumn get kind => text()(); // create | update | setCompleted | delete
  TextColumn get essentialId => text()();
  TextColumn get payload => text().withDefault(const Constant('{}'))(); // json
  DateTimeColumn get createdAt => dateTime()();
}

@DriftDatabase(tables: [CachedEssentials, OutboxEntries])
class AppDatabase extends _$AppDatabase {
  /// Production: a single on-disk database per install (lazily opened on first
  /// query). Web options point at the standard asset names so the cache works
  /// in the browser once `sqlite3.wasm` + `drift_worker.js` ship in `web/`;
  /// until then a web open simply fails and the caller degrades to online-only.
  AppDatabase()
    : super(
        driftDatabase(
          name: 'lull',
          web: DriftWebOptions(
            sqlite3Wasm: Uri.parse('sqlite3.wasm'),
            driftWorker: Uri.parse('drift_worker.js'),
          ),
        ),
      );

  /// Tests inject an in-memory executor (`NativeDatabase.memory()`).
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 1;

  // --- cache: today's essentials -------------------------------------------

  Future<List<CachedEssential>> essentialsForDate(String localDate) =>
      (select(cachedEssentials)
            ..where((t) => t.localDate.equals(localDate))
            ..orderBy([(t) => OrderingTerm(expression: t.slot)]))
          .get();

  Future<void> upsertEssential(CachedEssentialsCompanion row) =>
      into(cachedEssentials).insertOnConflictUpdate(row);

  Future<void> deleteEssential(String id) =>
      (delete(cachedEssentials)..where((t) => t.id.equals(id))).go();

  /// Replace the cached set for a day with the server's authoritative rows.
  Future<void> replaceEssentialsForDate(
    String localDate,
    List<CachedEssentialsCompanion> rows,
  ) => transaction(() async {
    await (delete(cachedEssentials)
          ..where((t) => t.localDate.equals(localDate)))
        .go();
    for (final row in rows) {
      await into(cachedEssentials).insert(row);
    }
  });

  // --- outbox: queued mutations --------------------------------------------

  Future<void> enqueue(OutboxEntriesCompanion entry) =>
      into(outboxEntries).insert(entry);

  Future<List<OutboxEntry>> pendingOutbox() =>
      (select(outboxEntries)
            ..orderBy([(t) => OrderingTerm(expression: t.seq)]))
          .get();

  Future<void> deleteOutboxEntry(int seq) =>
      (delete(outboxEntries)..where((t) => t.seq.equals(seq))).go();

  Future<bool> outboxIsEmpty() async =>
      (await (select(outboxEntries)..limit(1)).get()).isEmpty;
}

/// One database per app run, closed when the scope disposes. Tests override this
/// with an in-memory instance.
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});
