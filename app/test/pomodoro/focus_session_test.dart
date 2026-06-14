import 'package:flutter_test/flutter_test.dart';
import 'package:lull/features/pomodoro/domain/focus_phase.dart';
import 'package:lull/features/pomodoro/domain/focus_session.dart';

void main() {
  final start = DateTime.utc(2026, 6, 13, 9);

  FocusSession sessionAt(
    DateTime startedAt, {
    List<PauseInterval> pauses = const [],
  }) {
    return FocusSession(
      id: 'id',
      kind: FocusPhase.focus,
      startedAt: startedAt,
      plannedSeconds: 1500,
      idempotencyKey: 'key',
      focusesBefore: 0,
      createdAt: startedAt,
      pauses: pauses,
    );
  }

  group('anchor math', () {
    test('remaining derives from wall clock, never decrements', () {
      final s = sessionAt(start);
      expect(s.remainingSeconds(start), 1500);
      expect(s.remainingSeconds(start.add(const Duration(seconds: 100))), 1400);
      expect(s.remainingSeconds(start.add(const Duration(minutes: 25))), 0);
      // Past the planned end stays clamped at zero.
      expect(s.remainingSeconds(start.add(const Duration(minutes: 30))), 0);
    });

    test('closed pauses are excluded from elapsed time', () {
      final s = sessionAt(
        start,
        pauses: [
          PauseInterval(
            startedAt: start.add(const Duration(seconds: 20)),
            endedAt: start.add(const Duration(seconds: 50)),
          ),
        ],
      );
      // 100s of wall time minus a 30s pause = 70s elapsed.
      expect(s.remainingSeconds(start.add(const Duration(seconds: 100))), 1430);
    });

    test('an open pause freezes remaining time', () {
      final s = sessionAt(
        start,
        pauses: [
          PauseInterval(startedAt: start.add(const Duration(seconds: 60))),
        ],
      );
      final atPause = s.remainingSeconds(
        start.add(const Duration(seconds: 60)),
      );
      final muchLater = s.remainingSeconds(
        start.add(const Duration(minutes: 10)),
      );
      expect(atPause, 1440);
      expect(muchLater, 1440);
    });

    test('reward eligibility requires a clean, completed session', () {
      final clean = sessionAt(start).copyWith(
        endedAt: start.add(const Duration(minutes: 25)),
        endReason: SessionEndReason.completed,
      );
      expect(clean.rewardEligible, isTrue);

      final paused = clean.copyWith(rewardVoided: true);
      expect(paused.rewardEligible, isFalse);

      final aborted = sessionAt(
        start,
      ).copyWith(endedAt: start, endReason: SessionEndReason.aborted);
      expect(aborted.rewardEligible, isFalse);
    });
  });

  test('json round-trips every field', () {
    final original = FocusSession(
      id: 'abc',
      kind: FocusPhase.shortBreak,
      startedAt: start,
      plannedSeconds: 300,
      idempotencyKey: 'idem',
      focusesBefore: 2,
      createdAt: start,
      pauses: [
        PauseInterval(
          startedAt: start.add(const Duration(seconds: 10)),
          endedAt: start.add(const Duration(seconds: 25)),
        ),
        PauseInterval(startedAt: start.add(const Duration(seconds: 40))),
      ],
      endedAt: start.add(const Duration(minutes: 5)),
      endReason: SessionEndReason.completed,
      essentialId: 'e1',
      essentialTitle: 'finish the draft',
      rewardVoided: true,
    );

    final restored = FocusSession.fromJson(original.toJson());

    expect(restored.id, original.id);
    expect(restored.kind, original.kind);
    expect(restored.startedAt, original.startedAt);
    expect(restored.plannedSeconds, original.plannedSeconds);
    expect(restored.focusesBefore, original.focusesBefore);
    expect(restored.pauses.length, 2);
    expect(restored.pauses.first.endedAt, original.pauses.first.endedAt);
    expect(restored.pauses.last.isOpen, isTrue);
    expect(restored.endReason, SessionEndReason.completed);
    expect(restored.essentialTitle, 'finish the draft');
    expect(restored.rewardVoided, isTrue);
  });
}
