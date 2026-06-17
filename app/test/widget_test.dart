import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lull/app.dart';
import 'package:lull/features/auth/data/auth_repository.dart';
import 'package:lull/features/auth/domain/auth_user.dart';
import 'package:lull/features/essentials/data/essentials_repository.dart';
import 'package:lull/features/essentials/presentation/today_screen.dart';
import 'package:lull/features/notifications/data/devices_repository.dart';
import 'package:lull/features/notifications/data/notification_channel.dart';
import 'package:lull/features/notifications/data/push_tokens.dart';
import 'package:lull/features/onboarding/application/onboarding.dart';
import 'package:lull/features/onboarding/presentation/welcome_screen.dart';
import 'package:lull/features/pomodoro/data/presence_channel.dart';
import 'package:lull/features/pomodoro/data/session_api.dart';
import 'package:lull/features/pomodoro/data/session_channel.dart';
import 'package:lull/features/profile/data/profile_repository.dart';
import 'package:lull/features/stats/data/economy_channel.dart';
import 'package:lull/ui/components/lull_shell.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/fake_auth_repository.dart';
import 'support/fake_devices_repository.dart';
import 'support/fake_essentials_repository.dart';
import 'support/fake_profile_repository.dart';
import 'support/fake_push_tokens.dart';
import 'support/fake_realtime.dart';
import 'support/fake_session_channel.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  // Signed in; [onboarded] toggles whether the first-run welcome is behind us.
  overrides({required bool onboarded}) => [
    authRepositoryProvider.overrideWithValue(
      FakeAuthRepository(const AuthUser(id: 'test')),
    ),
    onboardingSeedProvider.overrideWithValue(onboarded),
    essentialsRepositoryProvider.overrideWithValue(FakeEssentialsRepository()),
    profileRepositoryProvider.overrideWithValue(FakeProfileRepository()),
    sessionApiProvider.overrideWithValue(const NoopSessionApi()),
    sessionChannelProvider.overrideWithValue(FakeSessionChannel()),
    economyChannelProvider.overrideWithValue(FakeEconomyChannel()),
    presenceChannelProvider.overrideWithValue(FakePresenceChannel()),
    notificationChannelProvider.overrideWithValue(FakeNotificationChannel()),
    pushTokensProvider.overrideWithValue(FakePushTokens(token: null)),
    devicesRepositoryProvider.overrideWithValue(FakeDevicesRepository()),
  ];

  // Fixed-duration pumps only — the breathing loop never settles, so
  // pumpAndSettle would time out. A few calm-length frames let the staggered
  // entrances land and the essentials load resolve.
  Future<void> settle(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 160));
    await tester.pump(const Duration(milliseconds: 320));
    await tester.pump(const Duration(milliseconds: 320));
  }

  testWidgets('boots into Today for a returning, onboarded user', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: overrides(onboarded: true),
        child: const LullApp(),
      ),
    );
    await settle(tester);

    expect(find.byType(LullShell), findsOneWidget);
    expect(find.byType(TodayScreen), findsOneWidget);
  });

  testWidgets('a new user sees the welcome, then "begin" lands on Today', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: overrides(onboarded: false),
        child: const LullApp(),
      ),
    );
    await settle(tester);

    expect(find.byType(WelcomeScreen), findsOneWidget);
    expect(find.byType(TodayScreen), findsNothing);

    await tester.tap(find.text('begin'));
    await settle(tester);

    // The router (rebuilt by marking onboarding seen) redirects on its own.
    expect(find.byType(WelcomeScreen), findsNothing);
    expect(find.byType(TodayScreen), findsOneWidget);
  });
}
