import 'package:flutter_test/flutter_test.dart';
import 'package:lull/features/pomodoro/domain/focus_phase.dart';
import 'package:lull/features/pomodoro/domain/pomodoro_cycle.dart';

void main() {
  group('PomodoroCycle.next', () {
    test('a focus is followed by a short break, tally incremented', () {
      final result = PomodoroCycle.next(FocusPhase.focus, 0);
      expect(result.phase, FocusPhase.shortBreak);
      expect(result.focusesAfter, 1);
    });

    test('the fourth focus triggers the long break', () {
      final result = PomodoroCycle.next(FocusPhase.focus, 3);
      expect(result.phase, FocusPhase.longBreak);
      expect(result.focusesAfter, 4);
    });

    test('a short break returns to focus, tally unchanged', () {
      final result = PomodoroCycle.next(FocusPhase.shortBreak, 2);
      expect(result.phase, FocusPhase.focus);
      expect(result.focusesAfter, 2);
    });

    test('a long break starts a fresh set', () {
      final result = PomodoroCycle.next(FocusPhase.longBreak, 4);
      expect(result.phase, FocusPhase.focus);
      expect(result.focusesAfter, 0);
    });
  });
}
