import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lull/features/pomodoro/domain/focus_phase.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// What the server returns when a session is started: its authoritative id and
/// anchor, plus its clock (for skew measurement in M5).
class SessionStartResult {
  const SessionStartResult({
    required this.serverId,
    required this.startedAt,
    required this.serverNow,
  });

  final String serverId;
  final DateTime startedAt;
  final DateTime serverNow;
}

/// Talks to the `session-validate` Edge Function — the server-authoritative
/// lifecycle. The engine still runs the local anchored countdown for
/// responsiveness; this is what makes a session *count*. A null `start` result
/// means we're offline: the timer runs locally but earns nothing (the
/// online-start rule).
abstract class SessionApi {
  Future<SessionStartResult?> start({
    required String idempotencyKey,
    required FocusPhase kind,
    required int plannedSeconds,
    String? essentialId,
    String? clientId,
  });
  Future<void> pause(String serverId);
  Future<void> resume(String serverId);
  Future<void> finalize({
    required String serverId,
    required String idempotencyKey,
    required bool clientPaused,
  });
}

String _serverKind(FocusPhase phase) => switch (phase) {
  FocusPhase.focus => 'focus',
  FocusPhase.shortBreak => 'short_break',
  FocusPhase.longBreak => 'long_break',
};

class SupabaseSessionApi implements SessionApi {
  SupabaseClient get _client => Supabase.instance.client;

  Future<Map<String, dynamic>?> _invoke(Map<String, dynamic> body) async {
    final res = await _client.functions.invoke('session-validate', body: body);
    final data = res.data;
    return data is Map<String, dynamic> ? data : null;
  }

  @override
  Future<SessionStartResult?> start({
    required String idempotencyKey,
    required FocusPhase kind,
    required int plannedSeconds,
    String? essentialId,
    String? clientId,
  }) async {
    try {
      final body = <String, dynamic>{
        'action': 'start',
        'idempotencyKey': idempotencyKey,
        'kind': _serverKind(kind),
        'plannedSeconds': plannedSeconds,
      };
      if (essentialId != null) body['essentialId'] = essentialId;
      if (clientId != null) body['clientId'] = clientId;
      final data = await _invoke(body);
      final session = data?['session'] as Map<String, dynamic>?;
      if (session == null) return null;
      return SessionStartResult(
        serverId: session['id'] as String,
        startedAt: DateTime.parse(session['started_at'] as String),
        serverNow: DateTime.parse(data!['serverNow'] as String),
      );
    } catch (_) {
      return null; // offline / error → uncredited local session
    }
  }

  @override
  Future<void> pause(String serverId) async {
    try {
      await _invoke({'action': 'pause', 'sessionId': serverId});
    } catch (_) {}
  }

  @override
  Future<void> resume(String serverId) async {
    try {
      await _invoke({'action': 'resume', 'sessionId': serverId});
    } catch (_) {}
  }

  @override
  Future<void> finalize({
    required String serverId,
    required String idempotencyKey,
    required bool clientPaused,
  }) async {
    try {
      await _invoke({
        'action': 'finalize',
        'sessionId': serverId,
        'idempotencyKey': idempotencyKey,
        'clientPaused': clientPaused,
      });
    } catch (_) {}
  }
}

/// No-op for offline-only contexts and tests: the engine falls back to a purely
/// local (uncredited) session.
class NoopSessionApi implements SessionApi {
  const NoopSessionApi();

  @override
  Future<SessionStartResult?> start({
    required String idempotencyKey,
    required FocusPhase kind,
    required int plannedSeconds,
    String? essentialId,
    String? clientId,
  }) async => null;

  @override
  Future<void> pause(String serverId) async {}

  @override
  Future<void> resume(String serverId) async {}

  @override
  Future<void> finalize({
    required String serverId,
    required String idempotencyKey,
    required bool clientPaused,
  }) async {}
}

final sessionApiProvider = Provider<SessionApi>((ref) => SupabaseSessionApi());
