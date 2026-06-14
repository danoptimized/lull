import 'package:flutter/foundation.dart';

import 'package:lull/features/pomodoro/domain/focus_phase.dart';

/// How a session ended. Mirrors the server's `end_reason` vocabulary so these
/// records sync without translation in M3.
enum SessionEndReason { completed, aborted, expired }

/// A single pause within a session. Open (no [endedAt]) while the user is
/// currently paused.
@immutable
class PauseInterval {
  const PauseInterval({required this.startedAt, this.endedAt});

  factory PauseInterval.fromJson(Map<String, dynamic> json) => PauseInterval(
    startedAt: DateTime.fromMillisecondsSinceEpoch(
      json['s'] as int,
      isUtc: true,
    ),
    endedAt: json['e'] == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(json['e'] as int, isUtc: true),
  );

  final DateTime startedAt;
  final DateTime? endedAt;

  bool get isOpen => endedAt == null;

  /// Duration of this pause, using [now] while it is still open.
  Duration durationAsOf(DateTime now) => (endedAt ?? now).difference(startedAt);

  PauseInterval close(DateTime at) =>
      PauseInterval(startedAt: startedAt, endedAt: at);

  Map<String, dynamic> toJson() => {
    's': startedAt.toUtc().millisecondsSinceEpoch,
    if (endedAt != null) 'e': endedAt!.toUtc().millisecondsSinceEpoch,
  };
}

/// The anchor record for one timer session.
///
/// The load-bearing idea of Lull's timer: a session is **not** a ticking
/// counter, it is `startedAt + plannedSeconds` minus recorded pauses. Remaining
/// time is always *derived* from the wall clock, so backgrounding, sleep, or a
/// killed-and-relaunched app never lose or drift the countdown. The server
/// becomes the authority on validity in M3; this is the local truth until then.
@immutable
class FocusSession {
  const FocusSession({
    required this.id,
    required this.kind,
    required this.startedAt,
    required this.plannedSeconds,
    required this.idempotencyKey,
    required this.focusesBefore,
    required this.createdAt,
    this.pauses = const [],
    this.endedAt,
    this.endReason,
    this.essentialId,
    this.essentialTitle,
    this.rewardVoided = false,
    this.serverId,
  });

  factory FocusSession.fromJson(Map<String, dynamic> json) => FocusSession(
    id: json['id'] as String,
    kind: FocusPhase.values.byName(json['kind'] as String),
    startedAt: DateTime.fromMillisecondsSinceEpoch(
      json['startedAt'] as int,
      isUtc: true,
    ),
    plannedSeconds: json['plannedSeconds'] as int,
    idempotencyKey: json['idempotencyKey'] as String,
    focusesBefore: json['focusesBefore'] as int,
    createdAt: DateTime.fromMillisecondsSinceEpoch(
      json['createdAt'] as int,
      isUtc: true,
    ),
    pauses: (json['pauses'] as List<dynamic>? ?? const [])
        .map((e) => PauseInterval.fromJson(e as Map<String, dynamic>))
        .toList(),
    endedAt: json['endedAt'] == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(
            json['endedAt'] as int,
            isUtc: true,
          ),
    endReason: json['endReason'] == null
        ? null
        : SessionEndReason.values.byName(json['endReason'] as String),
    essentialId: json['essentialId'] as String?,
    essentialTitle: json['essentialTitle'] as String?,
    rewardVoided: json['rewardVoided'] as bool? ?? false,
    serverId: json['serverId'] as String?,
  );

  final String id;
  final FocusPhase kind;
  final DateTime startedAt;
  final int plannedSeconds;
  final String idempotencyKey;

  /// Focuses completed in the current set before this session began. For a
  /// focus session, the 1-based index is `focusesBefore + 1`.
  final int focusesBefore;
  final DateTime createdAt;
  final List<PauseInterval> pauses;
  final DateTime? endedAt;
  final SessionEndReason? endReason;
  final String? essentialId;
  final String? essentialTitle;

  /// True once the user has paused at all. Under Lull's no-pause rule any pause
  /// forfeits this session's reward — but the session may still run to
  /// completion for the user's own record.
  final bool rewardVoided;

  /// The server's session id once `start` was accepted; null while the session
  /// is local-only (offline). Needed to address it on the server.
  final String? serverId;

  bool get isPaused => pauses.isNotEmpty && pauses.last.isOpen;
  bool get isActive => endedAt == null;

  int pausedSeconds(DateTime now) =>
      pauses.fold(0, (sum, p) => sum + p.durationAsOf(now).inSeconds);

  int elapsedSeconds(DateTime now) {
    final raw = now.difference(startedAt).inSeconds - pausedSeconds(now);
    return raw < 0 ? 0 : raw;
  }

  int remainingSeconds(DateTime now) {
    final remaining = plannedSeconds - elapsedSeconds(now);
    if (remaining < 0) return 0;
    if (remaining > plannedSeconds) return plannedSeconds;
    return remaining;
  }

  double progress(DateTime now) {
    if (plannedSeconds <= 0) return 0;
    return (elapsedSeconds(now) / plannedSeconds).clamp(0.0, 1.0);
  }

  bool isComplete(DateTime now) => elapsedSeconds(now) >= plannedSeconds;

  /// Provisional reward eligibility. The server makes the final call in M3/M4;
  /// locally, a session is eligible only if it completed without any pause.
  bool get rewardEligible =>
      !rewardVoided && endReason == SessionEndReason.completed;

  FocusSession copyWith({
    List<PauseInterval>? pauses,
    DateTime? endedAt,
    SessionEndReason? endReason,
    bool? rewardVoided,
    String? essentialId,
    String? essentialTitle,
    String? serverId,
  }) {
    return FocusSession(
      id: id,
      kind: kind,
      startedAt: startedAt,
      plannedSeconds: plannedSeconds,
      idempotencyKey: idempotencyKey,
      focusesBefore: focusesBefore,
      createdAt: createdAt,
      pauses: pauses ?? this.pauses,
      endedAt: endedAt ?? this.endedAt,
      endReason: endReason ?? this.endReason,
      essentialId: essentialId ?? this.essentialId,
      essentialTitle: essentialTitle ?? this.essentialTitle,
      rewardVoided: rewardVoided ?? this.rewardVoided,
      serverId: serverId ?? this.serverId,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'kind': kind.name,
    'startedAt': startedAt.toUtc().millisecondsSinceEpoch,
    'plannedSeconds': plannedSeconds,
    'idempotencyKey': idempotencyKey,
    'focusesBefore': focusesBefore,
    'createdAt': createdAt.toUtc().millisecondsSinceEpoch,
    'pauses': pauses.map((p) => p.toJson()).toList(),
    if (endedAt != null) 'endedAt': endedAt!.toUtc().millisecondsSinceEpoch,
    if (endReason != null) 'endReason': endReason!.name,
    if (essentialId != null) 'essentialId': essentialId,
    if (essentialTitle != null) 'essentialTitle': essentialTitle,
    'rewardVoided': rewardVoided,
    if (serverId != null) 'serverId': serverId,
  };
}
