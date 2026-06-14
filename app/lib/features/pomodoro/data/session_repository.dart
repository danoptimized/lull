import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lull/features/pomodoro/domain/focus_session.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Local persistence for the *active* anchor and recent history.
///
/// M1 stores the active session so a running timer survives a relaunch and
/// reconciles from its anchor. The interface is deliberately small: M2 swaps
/// the shared-preferences implementation for Drift (relational essentials +
/// a sync outbox) without touching the engine.
abstract class SessionRepository {
  Future<void> saveActive(FocusSession session);
  Future<FocusSession?> loadActive();
  Future<void> clearActive();
  Future<void> appendHistory(FocusSession finished);
  Future<List<FocusSession>> recentHistory({int limit});
}

/// Cross-platform (incl. web via localStorage) persistence. All reads are
/// defensive: corrupt JSON is dropped rather than thrown, so a bad record can
/// never wedge the timer.
class SharedPrefsSessionRepository implements SessionRepository {
  static const String _activeKey = 'lull.active_session.v1';
  static const String _historyKey = 'lull.session_history.v1';
  static const int _historyCap = 50;

  Future<SharedPreferences>? _prefsFuture;
  Future<SharedPreferences> get _prefs =>
      _prefsFuture ??= SharedPreferences.getInstance();

  @override
  Future<void> saveActive(FocusSession session) async {
    final prefs = await _prefs;
    await prefs.setString(_activeKey, jsonEncode(session.toJson()));
  }

  @override
  Future<FocusSession?> loadActive() async {
    final prefs = await _prefs;
    final raw = prefs.getString(_activeKey);
    if (raw == null) return null;
    try {
      return FocusSession.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      await prefs.remove(_activeKey);
      return null;
    }
  }

  @override
  Future<void> clearActive() async {
    final prefs = await _prefs;
    await prefs.remove(_activeKey);
  }

  @override
  Future<void> appendHistory(FocusSession finished) async {
    final prefs = await _prefs;
    final list = prefs.getStringList(_historyKey) ?? <String>[];
    list.insert(0, jsonEncode(finished.toJson()));
    if (list.length > _historyCap) {
      list.removeRange(_historyCap, list.length);
    }
    await prefs.setStringList(_historyKey, list);
  }

  @override
  Future<List<FocusSession>> recentHistory({int limit = 20}) async {
    final prefs = await _prefs;
    final list = prefs.getStringList(_historyKey) ?? <String>[];
    return list
        .take(limit)
        .map((e) {
          try {
            return FocusSession.fromJson(jsonDecode(e) as Map<String, dynamic>);
          } catch (_) {
            return null;
          }
        })
        .whereType<FocusSession>()
        .toList();
  }
}

/// In-memory implementation for tests and as a safe fallback.
class InMemorySessionRepository implements SessionRepository {
  InMemorySessionRepository([this._active]);

  FocusSession? _active;
  final List<FocusSession> _history = [];

  @override
  Future<void> saveActive(FocusSession session) async => _active = session;

  @override
  Future<FocusSession?> loadActive() async => _active;

  @override
  Future<void> clearActive() async => _active = null;

  @override
  Future<void> appendHistory(FocusSession finished) async =>
      _history.insert(0, finished);

  @override
  Future<List<FocusSession>> recentHistory({int limit = 20}) async =>
      _history.take(limit).toList();
}

final sessionRepositoryProvider = Provider<SessionRepository>(
  (ref) => SharedPrefsSessionRepository(),
);
