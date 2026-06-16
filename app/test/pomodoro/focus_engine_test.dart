import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lull/core/time/server_clock.dart';
import 'package:lull/features/pomodoro/application/focus_engine.dart';
import 'package:lull/features/pomodoro/application/session_cues.dart';
import 'package:lull/features/pomodoro/data/session_api.dart';
import 'package:lull/features/pomodoro/data/session_repository.dart';
import 'package:lull/features/pomodoro/domain/focus_phase.dart';
import 'package:lull/features/pomodoro/domain/focus_session.dart';
import 'package:lull/features/pomodoro/domain/focus_state.dart';

/// A clock the test advances by hand, so the anchor engine is fully
/// deterministic without any real elapsed time.
class FakeClock implements ServerClock {
  FakeClock(this._now);

  DateTime _now;

  void advance(Duration d) => _now = _now.add(d);

  @override
  DateTime now() => _now;

  @override
  Duration get skew => Duration.zero;
}

/// Records the lifecycle calls the engine makes and hands back a server id.
class RecordingSessionApi implements SessionApi {
  final List<String> calls = [];
  bool? finalizeClientPaused;
  String? startedEssentialId;

  @override
  Future<SessionStartResult?> start({
    required String idempotencyKey,
    required FocusPhase kind,
    required int plannedSeconds,
    String? essentialId,
    String? clientId,
  }) async {
    calls.add('start');
    startedEssentialId = essentialId;
    return SessionStartResult(
      serverId: 'server-123',
      startedAt: DateTime.utc(2026, 6, 13, 9),
      serverNow: DateTime.utc(2026, 6, 13, 9),
    );
  }

  @override
  Future<void> pause(String serverId) async => calls.add('pause:$serverId');

  @override
  Future<void> resume(String serverId) async => calls.add('resume:$serverId');

  @override
  Future<void> finalize({
    required String serverId,
    required String idempotencyKey,
    required bool clientPaused,
  }) async {
    calls.add('finalize:$serverId');
    finalizeClientPaused = clientPaused;
  }

  @override
  Future<DateTime?> serverTime() async => null;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ProviderContainer container;
  late FakeClock clock;
  late InMemorySessionRepository repo;

  ProviderContainer makeContainer({
    FocusSession? active,
    SessionApi api = const NoopSessionApi(),
  }) {
    clock = FakeClock(DateTime.utc(2026, 6, 13, 9));
    repo = InMemorySessionRepository(active);
    return ProviderContainer(
      overrides: [
        serverClockProvider.overrideWithValue(clock),
        sessionRepositoryProvider.overrideWithValue(repo),
        sessionCuesProvider.overrideWithValue(const NoopSessionCues()),
        sessionApiProvider.overrideWithValue(api),
        focusTickerEnabledProvider.overrideWithValue(false),
      ],
    );
  }

  FocusEngine engine() => container.read(focusEngineProvider.notifier);
  FocusState read() => container.read(focusEngineProvider);

  Future<void> runToCompletion() async {
    await engine().begin();
    clock.advance(Duration(seconds: read().plannedSeconds));
    await engine().debugTick();
  }

  setUp(() => container = makeContainer());
  tearDown(() => container.dispose());

  test('starts ready on a full 25-minute focus', () {
    final s = read();
    expect(s.status, FocusStatus.ready);
    expect(s.phase, FocusPhase.focus);
    expect(s.remainingSeconds, 1500);
    expect(s.sessionIndex, 1);
  });

  test(
    'begin anchors a session and remaining derives from the clock',
    () async {
      await engine().begin();
      expect(read().status, FocusStatus.running);
      expect(read().session, isNotNull);

      clock.advance(const Duration(seconds: 60));
      await engine().debugTick();
      expect(read().remainingSeconds, 1440);

      // The active anchor is persisted for relaunch.
      expect(await repo.loadActive(), isNotNull);
    },
  );

  test(
    'pausing freezes the clock and voids the reward (no-pause rule)',
    () async {
      await engine().begin();
      clock.advance(const Duration(seconds: 60));
      await engine().debugTick();

      await engine().pause();
      expect(read().status, FocusStatus.paused);
      expect(read().rewardVoided, isTrue);

      // Time passes while paused — remaining must not move.
      clock.advance(const Duration(seconds: 90));
      await engine().debugTick();
      expect(read().remainingSeconds, 1440);

      await engine().resume();
      expect(read().status, FocusStatus.running);

      // 60s more of real focus after resuming: 60 + 60 = 120 elapsed.
      clock.advance(const Duration(seconds: 60));
      await engine().debugTick();
      expect(read().remainingSeconds, 1380);
    },
  );

  test('completing a focus advances to a short break and logs it', () async {
    await engine().begin();
    clock.advance(const Duration(minutes: 25));
    await engine().debugTick();

    final s = read();
    expect(s.status, FocusStatus.ready);
    expect(s.phase, FocusPhase.shortBreak);
    expect(s.focusesBefore, 1);
    expect(s.lastCompleted, FocusPhase.focus);
    expect(s.completionPulse, 1);

    final history = await repo.recentHistory();
    expect(history.single.endReason, SessionEndReason.completed);
    expect(await repo.loadActive(), isNull);
  });

  test('a paused-then-finished session is logged reward-ineligible', () async {
    await engine().begin();
    clock.advance(const Duration(seconds: 60));
    await engine().debugTick();
    await engine().pause();
    await engine().resume();
    clock.advance(const Duration(minutes: 25));
    await engine().debugTick();

    final finished = (await repo.recentHistory()).single;
    expect(finished.endReason, SessionEndReason.completed);
    expect(finished.rewardVoided, isTrue);
    expect(finished.rewardEligible, isFalse);
  });

  test('four focuses lead to a long break, then a fresh set', () async {
    await runToCompletion(); // focus 1 -> short break
    expect(read().phase, FocusPhase.shortBreak);
    expect(read().focusesBefore, 1);

    await runToCompletion(); // short break -> focus
    await runToCompletion(); // focus 2 -> short break
    await runToCompletion(); // short break -> focus
    await runToCompletion(); // focus 3 -> short break
    await runToCompletion(); // short break -> focus
    await runToCompletion(); // focus 4 -> LONG break
    expect(read().phase, FocusPhase.longBreak);
    expect(read().focusesBefore, 4);

    await runToCompletion(); // long break -> fresh focus
    expect(read().phase, FocusPhase.focus);
    expect(read().focusesBefore, 0);
  });

  test('give up resets the phase and rewards nothing', () async {
    await engine().begin();
    clock.advance(const Duration(seconds: 120));
    await engine().debugTick();

    await engine().abort();
    final s = read();
    expect(s.status, FocusStatus.ready);
    expect(s.phase, FocusPhase.focus);
    expect(s.remainingSeconds, 1500);
    expect(
      (await repo.recentHistory()).single.endReason,
      SessionEndReason.aborted,
    );
  });

  group('server lifecycle', () {
    test('begin links the server id and completion finalizes it', () async {
      final api = RecordingSessionApi();
      container = makeContainer(api: api);

      await engine().begin();
      expect(read().session?.serverId, 'server-123');
      expect(api.calls, contains('start'));

      clock.advance(const Duration(minutes: 25));
      await engine().debugTick();
      expect(api.calls, contains('finalize:server-123'));
      expect(api.finalizeClientPaused, isFalse);
    });

    test(
      'pause and resume are reported, and a pause voids at finalize',
      () async {
        final api = RecordingSessionApi();
        container = makeContainer(api: api);

        await engine().begin();
        await engine().pause();
        await engine().resume();
        expect(api.calls, contains('pause:server-123'));
        expect(api.calls, contains('resume:server-123'));

        clock.advance(const Duration(minutes: 25));
        await engine().debugTick();
        expect(api.finalizeClientPaused, isTrue);
      },
    );

    test('give up finalizes the server session too', () async {
      final api = RecordingSessionApi();
      container = makeContainer(api: api);

      await engine().begin();
      await engine().abort();
      expect(api.calls, contains('finalize:server-123'));
    });

    test('selectEssential(null) clears it so begin sends no essential', () async {
      final api = RecordingSessionApi();
      container = makeContainer(api: api);

      engine().selectEssential('e1', 'write the draft');
      expect(read().essentialId, 'e1');

      // All essentials done → a null selection must actually clear, or begin()
      // would credit the finished/stale task.
      engine().selectEssential(null, null);
      expect(read().essentialId, isNull);
      expect(read().essentialTitle, isNull);

      await engine().begin();
      expect(api.startedEssentialId, isNull);
      expect(read().session?.essentialId, isNull);
    });
  });

  group('rehydration', () {
    test('rejoins a focus that was running before launch', () async {
      final startedAt = DateTime.utc(2026, 6, 13, 8, 58); // 120s before 9:00
      container = makeContainer(
        active: FocusSession(
          id: 's',
          kind: FocusPhase.focus,
          startedAt: startedAt,
          plannedSeconds: 1500,
          idempotencyKey: 'k',
          focusesBefore: 0,
          createdAt: startedAt,
        ),
      );
      await engine().debugHydrate();

      final s = read();
      expect(s.status, FocusStatus.running);
      expect(s.phase, FocusPhase.focus);
      expect(s.remainingSeconds, 1380);
    });

    test('finalizes a session that completed while the app was gone', () async {
      final startedAt = DateTime.utc(2026, 6, 13, 7); // hours ago
      container = makeContainer(
        active: FocusSession(
          id: 's',
          kind: FocusPhase.focus,
          startedAt: startedAt,
          plannedSeconds: 1500,
          idempotencyKey: 'k',
          focusesBefore: 0,
          createdAt: startedAt,
        ),
      );
      await engine().debugHydrate();

      final s = read();
      expect(s.status, FocusStatus.ready);
      expect(s.phase, FocusPhase.shortBreak);
      expect(s.focusesBefore, 1);
      expect(await repo.loadActive(), isNull);
    });

    test('restores a paused session as paused', () async {
      final startedAt = DateTime.utc(2026, 6, 13, 8, 59);
      container = makeContainer(
        active: FocusSession(
          id: 's',
          kind: FocusPhase.focus,
          startedAt: startedAt,
          plannedSeconds: 1500,
          idempotencyKey: 'k',
          focusesBefore: 0,
          createdAt: startedAt,
          rewardVoided: true,
          pauses: [
            PauseInterval(
              startedAt: startedAt.add(const Duration(seconds: 30)),
            ),
          ],
        ),
      );
      await engine().debugHydrate();

      final s = read();
      expect(s.status, FocusStatus.paused);
      expect(s.rewardVoided, isTrue);
    });
  });
}
