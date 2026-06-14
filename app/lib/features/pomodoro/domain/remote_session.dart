import 'package:flutter/foundation.dart';

/// A session as seen from *another* device — built from a realtime broadcast or
/// the initial fetch. Like the local anchor, its countdown is derived from
/// `startedAt` against server time, so a watching device renders it live with no
/// per-tick traffic. Uses the server's wire shape (ISO timestamps, snake_case).
@immutable
class RemoteSession {
  const RemoteSession({
    required this.id,
    required this.kind,
    required this.startedAt,
    required this.plannedSeconds,
    this.pauses = const [],
    this.endedAt,
    this.clientId,
    this.essentialId,
  });

  factory RemoteSession.fromJson(Map<String, dynamic> json) {
    final rawPauses = (json['pause_intervals'] as List<dynamic>? ?? const []);
    return RemoteSession(
      id: json['id'] as String,
      kind: json['kind'] as String? ?? 'focus',
      startedAt: DateTime.parse(json['started_at'] as String),
      plannedSeconds: (json['planned_seconds'] as num).toInt(),
      pauses: rawPauses
          .map((p) => p as Map<String, dynamic>)
          .map(
            (p) => RemotePause(
              DateTime.parse(p['start'] as String),
              p['end'] == null ? null : DateTime.parse(p['end'] as String),
            ),
          )
          .toList(growable: false),
      endedAt: json['ended_at'] == null
          ? null
          : DateTime.parse(json['ended_at'] as String),
      clientId: json['client_id'] as String?,
      essentialId: json['essential_id'] as String?,
    );
  }

  final String id;
  final String kind;
  final DateTime startedAt;
  final int plannedSeconds;
  final List<RemotePause> pauses;
  final DateTime? endedAt;
  final String? clientId;
  final String? essentialId;

  bool get isActive => endedAt == null;
  bool get isFocus => kind == 'focus';
  bool get isPaused => pauses.isNotEmpty && pauses.last.end == null;

  int _pausedSeconds(DateTime serverNow) => pauses.fold(0, (sum, p) {
    final end = p.end ?? serverNow;
    final secs = end.difference(p.start).inSeconds;
    return sum + (secs < 0 ? 0 : secs);
  });

  int remainingSeconds(DateTime serverNow) {
    final elapsed =
        serverNow.difference(startedAt).inSeconds - _pausedSeconds(serverNow);
    final remaining = plannedSeconds - (elapsed < 0 ? 0 : elapsed);
    if (remaining < 0) return 0;
    if (remaining > plannedSeconds) return plannedSeconds;
    return remaining;
  }

  double progress(DateTime serverNow) {
    if (plannedSeconds <= 0) return 0;
    return ((plannedSeconds - remainingSeconds(serverNow)) / plannedSeconds)
        .clamp(0.0, 1.0);
  }
}

@immutable
class RemotePause {
  const RemotePause(this.start, this.end);
  final DateTime start;
  final DateTime? end;
}
