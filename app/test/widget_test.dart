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

  testWidgets('lull boots into the today screen when signed in', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(
            FakeAuthRepository(const AuthUser(id: 'test')),
          ),
          // A returning, already-onboarded user lands straight on Today.
          onboardingSeedProvider.overrideWithValue(true),
          essentialsRepositoryProvider.overrideWithValue(
            FakeEssentialsRepository(),
          ),
          profileRepositoryProvider.overrideWithValue(FakeProfileRepository()),
          sessionApiProvider.overrideWithValue(const NoopSessionApi()),
          sessionChannelProvider.overrideWithValue(FakeSessionChannel()),
          economyChannelProvider.overrideWithValue(FakeEconomyChannel()),
          presenceChannelProvider.overrideWithValue(FakePresenceChannel()),
          notificationChannelProvider.overrideWithValue(
            FakeNotificationChannel(),
          ),
          pushTokensProvider.overrideWithValue(FakePushTokens(token: null)),
          devicesRepositoryProvider.overrideWithValue(FakeDevicesRepository()),
        ],
        child: const LullApp(),
      ),
    );

    // Fixed-duration pumps only — the breathing loop never settles, so
    // pumpAndSettle would time out. A few calm-length frames let the
    // staggered entrances land and the essentials load resolve.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 160));
    await tester.pump(const Duration(milliseconds: 320));
    await tester.pump(const Duration(milliseconds: 320));

    expect(find.byType(LullShell), findsOneWidget);
    expect(find.byType(TodayScreen), findsOneWidget);
  });
}
