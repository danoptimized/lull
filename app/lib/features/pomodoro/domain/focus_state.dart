import 'package:flutter/foundation.dart';

import 'package:lull/features/pomodoro/domain/focus_phase.dart';
import 'package:lull/features/pomodoro/domain/focus_session.dart';
import 'package:lull/features/pomodoro/domain/pomodoro_cycle.dart';

enum FocusStatus { ready, running, paused }

/// The engine's snapshot the UI renders from.
///
/// [remainingSeconds] is a *derived* value, recomputed from the active
/// [session]'s anchor each tick — never decremented. The session itself is
/// excluded from equality so a pure pause-list change doesn't rebuild the dial;
/// everything the UI shows lives in the compared fields.
@immutable
class FocusState {
  const FocusState({
    required this.phase,
    required this.status,
    required this.plannedSeconds,
    required this.remainingSeconds,
    required this.focusesBefore,
    this.session,
    this.essentialId,
    this.essentialTitle,
    this.rewardVoided = false,
    this.lastCompleted,
    this.completionPulse = 0,
  });

  /// A not-yet-started session for [phase], the clock reset to its full length.
  factory FocusState.ready(
    FocusPhase phase, {
    required int focusesBefore,
    String? essentialId,
    String? essentialTitle,
    FocusPhase? lastCompleted,
    int completionPulse = 0,
  }) {
    final planned = PomodoroCycle.plannedSecondsFor(phase);
    return FocusState(
      phase: phase,
      status: FocusStatus.ready,
      plannedSeconds: planned,
      remainingSeconds: planned,
      focusesBefore: focusesBefore,
      essentialId: essentialId,
      essentialTitle: essentialTitle,
      lastCompleted: lastCompleted,
      completionPulse: completionPulse,
    );
  }

  final FocusPhase phase;
  final FocusStatus status;
  final int plannedSeconds;
  final int remainingSeconds;
  final int focusesBefore;
  final FocusSession? session;
  final String? essentialId;
  final String? essentialTitle;
  final bool rewardVoided;

  /// The phase that most recently completed, and a monotonic counter that ticks
  /// up on each completion — the UI watches [completionPulse] to fire a brief,
  /// gentle celebration without the engine reaching into the widget tree.
  final FocusPhase? lastCompleted;
  final int completionPulse;

  bool get running => status == FocusStatus.running;
  bool get paused => status == FocusStatus.paused;
  bool get ready => status == FocusStatus.ready;
  bool get isFocus => phase == FocusPhase.focus;
  bool get isActive => status != FocusStatus.ready;

  /// 1-based index of the current focus within its set (1..focusesPerSet).
  int get sessionIndex => focusesBefore + 1;
  int get sessionsPerSet => PomodoroCycle.focusesPerSet;

  double get progress {
    if (plannedSeconds <= 0) return 0;
    return ((plannedSeconds - remainingSeconds) / plannedSeconds).clamp(
      0.0,
      1.0,
    );
  }

  FocusState copyWith({
    FocusStatus? status,
    int? remainingSeconds,
    FocusSession? session,
    bool clearSession = false,
    String? essentialId,
    String? essentialTitle,
    bool clearEssential = false,
    bool? rewardVoided,
    FocusPhase? lastCompleted,
    int? completionPulse,
  }) {
    return FocusState(
      phase: phase,
      status: status ?? this.status,
      plannedSeconds: plannedSeconds,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      focusesBefore: focusesBefore,
      // The `x ?? this.x` idiom can't express "set to null", so explicit clear
      // flags exist for detaching the session or the linked essential.
      session: clearSession ? null : (session ?? this.session),
      essentialId: clearEssential ? null : (essentialId ?? this.essentialId),
      essentialTitle: clearEssential
          ? null
          : (essentialTitle ?? this.essentialTitle),
      rewardVoided: rewardVoided ?? this.rewardVoided,
      lastCompleted: lastCompleted ?? this.lastCompleted,
      completionPulse: completionPulse ?? this.completionPulse,
    );
  }

  // `session` is intentionally excluded: the UI derives everything it shows
  // from the scalar fields, so a pause-list mutation alone must not rebuild.
  @override
  bool operator ==(Object other) =>
      other is FocusState &&
      other.phase == phase &&
      other.status == status &&
      other.plannedSeconds == plannedSeconds &&
      other.remainingSeconds == remainingSeconds &&
      other.focusesBefore == focusesBefore &&
      other.essentialId == essentialId &&
      other.essentialTitle == essentialTitle &&
      other.rewardVoided == rewardVoided &&
      other.lastCompleted == lastCompleted &&
      other.completionPulse == completionPulse;

  @override
  int get hashCode => Object.hash(
    phase,
    status,
    plannedSeconds,
    remainingSeconds,
    focusesBefore,
    essentialId,
    essentialTitle,
    rewardVoided,
    lastCompleted,
    completionPulse,
  );
}
