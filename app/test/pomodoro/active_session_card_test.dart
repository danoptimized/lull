import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lull/core/theme/theme.dart';
import 'package:lull/core/time/server_clock.dart';
import 'package:lull/features/pomodoro/application/focus_engine.dart';
import 'package:lull/features/pomodoro/application/session_cues.dart';
import 'package:lull/features/pomodoro/data/session_api.dart';
import 'package:lull/features/pomodoro/data/session_repository.dart';
import 'package:lull/features/pomodoro/presentation/widgets/active_session_card.dart';

/// A clock that never moves — the card only needs a deterministic anchor, not
/// elapsed time (the heartbeat ticker is disabled below).
class _FixedClock implements ServerClock {
  _FixedClock(this._now);

  final DateTime _now;

  @override
  DateTime now() => _now;

  @override
  Duration get skew => Duration.zero;
}

void main() {
  testWidgets('hidden while ready; shows the live session once active', (
    tester,
  ) async {
    final container = ProviderContainer(
      overrides: [
        serverClockProvider.overrideWithValue(
          _FixedClock(DateTime.utc(2026, 6, 13, 9)),
        ),
        sessionRepositoryProvider.overrideWithValue(
          InMemorySessionRepository(),
        ),
        sessionCuesProvider.overrideWithValue(const NoopSessionCues()),
        sessionApiProvider.overrideWithValue(const NoopSessionApi()),
        focusTickerEnabledProvider.overrideWithValue(false),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: buildLullTheme(Brightness.dark),
          home: const Scaffold(body: ActiveSessionCard()),
        ),
      ),
    );
    // Flush the engine's hydrate microtask (no stored session → stays ready).
    await tester.pump();

    // Ready: the banner renders nothing.
    expect(find.text('FOCUS IN PROGRESS'), findsNothing);
    expect(find.text('tap to return'), findsNothing);

    // Running: a prominent, live banner appears.
    await container.read(focusEngineProvider.notifier).begin();
    await tester.pump();
    expect(find.text('FOCUS IN PROGRESS'), findsOneWidget);
    expect(find.text('tap to return'), findsOneWidget);
    // 25:00 focus, just begun against the fixed clock.
    expect(find.textContaining('25:00'), findsOneWidget);

    // Paused: the banner stays, relabelled.
    await container.read(focusEngineProvider.notifier).pause();
    await tester.pump();
    expect(find.text('PAUSED'), findsOneWidget);
    expect(find.text('FOCUS IN PROGRESS'), findsNothing);
  });
}
