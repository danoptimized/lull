/// The phase of a pomodoro cycle.
enum FocusPhase {
  focus('focus'),
  shortBreak('break — breathe'),
  longBreak('a longer rest');

  const FocusPhase(this.label);

  /// Lowercase display label in the Lull voice (DESIGN.md). Callers that
  /// render it in the `label` text style uppercase it themselves.
  final String label;
}
