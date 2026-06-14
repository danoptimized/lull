import 'package:lull/features/pomodoro/domain/focus_phase.dart';

/// The fixed v1 pomodoro cadence: 25 on / 5 off, with a longer rest after four
/// focuses. Durations become user-configurable post-v1, so every consumer
/// reads them from here rather than hard-coding minutes.
class PomodoroCycle {
  const PomodoroCycle._();

  static const int focusSeconds = 25 * 60;
  static const int shortBreakSeconds = 5 * 60;
  static const int longBreakSeconds = 15 * 60;

  /// Focuses completed before a long break replaces the short one.
  static const int focusesPerSet = 4;

  static int plannedSecondsFor(FocusPhase phase) => switch (phase) {
    FocusPhase.focus => focusSeconds,
    FocusPhase.shortBreak => shortBreakSeconds,
    FocusPhase.longBreak => longBreakSeconds,
  };

  /// The phase that follows [completed], given how many focuses are done in the
  /// current set ([focusesBefore] counts focuses completed *before* this one).
  /// Returns the next phase and the focuses-completed tally afterwards.
  static ({FocusPhase phase, int focusesAfter}) next(
    FocusPhase completed,
    int focusesBefore,
  ) {
    switch (completed) {
      case FocusPhase.focus:
        final done = focusesBefore + 1;
        final longBreakDue = done >= focusesPerSet;
        return (
          phase: longBreakDue ? FocusPhase.longBreak : FocusPhase.shortBreak,
          focusesAfter: done,
        );
      case FocusPhase.longBreak:
        return (phase: FocusPhase.focus, focusesAfter: 0);
      case FocusPhase.shortBreak:
        return (phase: FocusPhase.focus, focusesAfter: focusesBefore);
    }
  }
}
