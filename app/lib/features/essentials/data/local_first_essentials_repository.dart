import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/foundation.dart';

import 'package:lull/core/util/ids.dart';
import 'package:lull/data/local/app_database.dart';
import 'package:lull/features/essentials/data/essentials_repository.dart';
import 'package:lull/features/essentials/domain/essential.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

/// An [EssentialsRepository] that reads and writes a local Drift cache first,
/// then reconciles with the remote (Supabase) repository.
///
/// - **Reads** serve the cache, so today's essentials render instantly and work
///   with no network. When online and the outbox is drained, the cache is
///   refreshed from the server (the source of truth).
/// - **Writes** update the cache optimistically and append to a durable outbox,
///   then try to flush it immediately. Offline, the edits stay queued and the
///   UI still reflects them; on the next online interaction the queue replays in
///   order (last write wins per field).
///
/// If the local store can't be opened — e.g. web without the sqlite3 wasm assets
/// — every method degrades to talking to the remote directly, which is exactly
/// the pre-offline behavior, so nothing regresses.
class LocalFirstEssentialsRepository implements EssentialsRepository {
  LocalFirstEssentialsRepository(this._remote, this._db);

  final EssentialsRepository _remote;
  final AppDatabase _db;

  /// Flips to false the first time a local-store operation throws; thereafter
  /// the repository is a pass-through to [_remote].
  bool _localOk = true;

  String get _today => todayLocalDate();

  @override
  Future<List<Essential>> fetchToday() async {
    if (!_localOk) return _remote.fetchToday();
    try {
      await _drain();
      // Only trust the server to replace the cache once our own edits are in.
      if (await _db.outboxIsEmpty()) {
        try {
          final remote = await _remote.fetchToday();
          await _db.replaceEssentialsForDate(
            _today,
            remote.map(_toCompanion).toList(growable: false),
          );
        } catch (_) {
          // Offline (or server hiccup): fall through and serve the cache.
        }
      }
      final rows = await _db.essentialsForDate(_today);
      return rows.map(_toEssential).toList(growable: false);
    } catch (error, stack) {
      _disableLocal(error, stack);
      return _remote.fetchToday();
    }
  }

  @override
  Future<void> create({
    required String id,
    required int slot,
    required String title,
    required int targetPomodoros,
  }) async {
    if (!_localOk) {
      return _remote.create(
        id: id,
        slot: slot,
        title: title,
        targetPomodoros: targetPomodoros,
      );
    }
    try {
      await _db.upsertEssential(
        CachedEssentialsCompanion.insert(
          id: id,
          localDate: _today,
          slot: slot,
          title: title,
          targetPomodoros: targetPomodoros,
        ),
      );
      await _enqueue('create', id, {
        'slot': slot,
        'title': title,
        'target': targetPomodoros,
      });
      await _drain();
    } catch (error, stack) {
      _disableLocal(error, stack);
      await _remote.create(
        id: id,
        slot: slot,
        title: title,
        targetPomodoros: targetPomodoros,
      );
    }
  }

  @override
  Future<void> update({
    required String id,
    required String title,
    required int targetPomodoros,
  }) async {
    if (!_localOk) {
      return _remote.update(id: id, title: title, targetPomodoros: targetPomodoros);
    }
    try {
      await _patchCache(
        id,
        (e) => e.copyWith(title: title, targetPomodoros: targetPomodoros),
      );
      await _enqueue('update', id, {'title': title, 'target': targetPomodoros});
      await _drain();
    } catch (error, stack) {
      _disableLocal(error, stack);
      await _remote.update(id: id, title: title, targetPomodoros: targetPomodoros);
    }
  }

  @override
  Future<void> setCompleted({required String id, required bool done}) async {
    if (!_localOk) return _remote.setCompleted(id: id, done: done);
    try {
      await _patchCache(
        id,
        (e) => done
            ? e.copyWith(completedAt: DateTime.now())
            : e.copyWith(clearCompletedAt: true),
      );
      await _enqueue('setCompleted', id, {'done': done});
      await _drain();
    } catch (error, stack) {
      _disableLocal(error, stack);
      await _remote.setCompleted(id: id, done: done);
    }
  }

  @override
  Future<void> delete(String id) async {
    if (!_localOk) return _remote.delete(id);
    try {
      await _db.deleteEssential(id);
      await _enqueue('delete', id, const {});
      await _drain();
    } catch (error, stack) {
      _disableLocal(error, stack);
      await _remote.delete(id);
    }
  }

  // --- outbox plumbing ------------------------------------------------------

  Future<void> _enqueue(String kind, String id, Map<String, Object?> payload) =>
      _db.enqueue(
        OutboxEntriesCompanion.insert(
          opId: newUuidV4(),
          kind: kind,
          essentialId: id,
          payload: Value(jsonEncode(payload)),
          createdAt: DateTime.now(),
        ),
      );

  /// Replay queued mutations in order. A transient failure (offline) stops the
  /// drain so ordering is preserved and we retry on the next one; a permanent
  /// failure — the server reached us and rejected the request (e.g. a stale
  /// create hitting the slot constraint) — drops just that entry, so one poison
  /// item can't stall the whole queue forever.
  Future<void> _drain() async {
    await _coalesce();
    for (final entry in await _db.pendingOutbox()) {
      try {
        await _applyRemote(entry);
        await _db.deleteOutboxEntry(entry.seq);
      } on PostgrestException catch (e) {
        if (!_isPermanent(e)) break; // transient (5xx/429) — keep, retry later
        debugPrint('lull · dropping rejected outbox entry ${entry.seq}: ${e.message}');
        await _db.deleteOutboxEntry(entry.seq);
      } catch (_) {
        break; // couldn't reach the server — keep the queue, retry later
      }
    }
  }

  /// A PostgREST error is permanent only if a retry can never succeed: a
  /// Postgres integrity/permission failure (SQLSTATE class 23xxx, or 42501 RLS)
  /// or a 4xx HTTP status. Transient 5xx/429/408, an unknown/empty code, or a
  /// network error are NOT permanent and keep the entry queued — postgrest does
  /// not retry writes, so a transient 5xx surfaces here as a PostgrestException
  /// and must not be mistaken for a rejection (that would lose the user's edit).
  bool _isPermanent(PostgrestException e) {
    final code = e.code;
    if (code == null) return false;
    if (code.startsWith('23') || code == '42501') return true;
    final status = int.tryParse(code);
    if (status != null) {
      return status >= 400 && status < 500 && status != 408 && status != 429;
    }
    return false;
  }

  /// An offline create followed by a delete of the same (never-synced) row nets
  /// to nothing on the server, so drop every queued op for such ids before
  /// draining — avoids needless round-trips and a delete outrunning its create.
  Future<void> _coalesce() async {
    final pending = await _db.pendingOutbox();
    final created = <String>{};
    final deleted = <String>{};
    for (final e in pending) {
      if (e.kind == 'create') created.add(e.essentialId);
      if (e.kind == 'delete') deleted.add(e.essentialId);
    }
    final cancelled = created.intersection(deleted);
    for (final e in pending) {
      if (cancelled.contains(e.essentialId)) await _db.deleteOutboxEntry(e.seq);
    }
  }

  Future<void> _applyRemote(OutboxEntry entry) async {
    final payload = entry.payload.isEmpty
        ? const <String, dynamic>{}
        : jsonDecode(entry.payload) as Map<String, dynamic>;
    switch (entry.kind) {
      case 'create':
        await _remote.create(
          id: entry.essentialId,
          slot: payload['slot'] as int,
          title: payload['title'] as String,
          targetPomodoros: payload['target'] as int,
        );
      case 'update':
        await _remote.update(
          id: entry.essentialId,
          title: payload['title'] as String,
          targetPomodoros: payload['target'] as int,
        );
      case 'setCompleted':
        await _remote.setCompleted(
          id: entry.essentialId,
          done: payload['done'] as bool,
        );
      case 'delete':
        await _remote.delete(entry.essentialId);
    }
  }

  // --- cache <-> domain mapping --------------------------------------------

  Future<void> _patchCache(String id, Essential Function(Essential) edit) async {
    for (final row in await _db.essentialsForDate(_today)) {
      if (row.id == id) {
        await _db.upsertEssential(_toCompanion(edit(_toEssential(row))));
        return;
      }
    }
  }

  CachedEssentialsCompanion _toCompanion(Essential e) =>
      CachedEssentialsCompanion.insert(
        id: e.id,
        localDate: _today,
        slot: e.slot,
        title: e.title,
        targetPomodoros: e.targetPomodoros,
        completedPomodoros: Value(e.completedPomodoros),
        completedAt: Value(e.completedAt),
      );

  Essential _toEssential(CachedEssential r) => Essential(
    id: r.id,
    slot: r.slot,
    title: r.title,
    targetPomodoros: r.targetPomodoros,
    completedPomodoros: r.completedPomodoros,
    completedAt: r.completedAt,
  );

  void _disableLocal(Object error, StackTrace stack) {
    _localOk = false;
    debugPrint('lull · offline cache disabled, using remote only: $error\n$stack');
  }
}
