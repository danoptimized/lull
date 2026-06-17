// Store screenshots — rendered from the real screens at the App Store's
// mandatory device sizes, in the brand's dark theme. Written to
// ../../store/screenshots/ (repo root) for upload to Play / App Store Connect.
//
// Not part of the default suite (the `store` tag is skipped). Generate with:
//   flutter test --update-goldens --run-skipped -t store test/store
//
// These are clean app screens at exact dimensions — a solid base; add framing /
// captions in your store tooling if desired.
@Tags(['store'])
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lull/core/router/app_router.dart';
import 'package:lull/core/theme/theme.dart';
import 'package:lull/features/auth/data/auth_repository.dart';
import 'package:lull/features/auth/domain/auth_user.dart';
import 'package:lull/features/auth/presentation/sign_in_screen.dart';
import 'package:lull/features/essentials/data/essentials_repository.dart';
import 'package:lull/features/essentials/domain/essential.dart';
import 'package:lull/features/notifications/data/notification_channel.dart';
import 'package:lull/features/onboarding/application/onboarding.dart';
import 'package:lull/features/pomodoro/data/presence_channel.dart';
import 'package:lull/features/pomodoro/data/session_api.dart';
import 'package:lull/features/pomodoro/data/session_channel.dart';
import 'package:lull/features/pomodoro/presentation/focus_screen.dart';
import 'package:lull/features/profile/data/profile_repository.dart';
import 'package:lull/features/stats/data/economy_channel.dart';
import 'package:lull/features/stats/data/stats_repository.dart';
import 'package:lull/features/stats/presentation/stats_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/fake_auth_repository.dart';
import '../support/fake_essentials_repository.dart';
import '../support/fake_profile_repository.dart';
import '../support/fake_realtime.dart';
import '../support/fake_session_channel.dart';
import '../support/fake_stats_repository.dart';

/// (logical size, device pixel ratio) → exact physical px the stores want.
class _Device {
  const _Device(this.size, this.dpr);
  final Size size;
  final double dpr;
}

// iPhone 6.7" → 1290×2796 (App Store mandatory). iPad 12.9" → 2048×2732.
const _devices = <String, _Device>{
  'iphone67': _Device(Size(430, 932), 3.0),
  'ipad13': _Device(Size(1024, 1366), 2.0),
};

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});

    final manrope = FontLoader('Manrope');
    for (final weight in const [300, 400, 500, 600, 700, 800]) {
      final bytes = File('assets/fonts/Manrope-$weight.ttf').readAsBytesSync();
      manrope.addFont(Future.value(ByteData.sublistView(bytes)));
    }
    await manrope.load();
    final material = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await material.load();
    final cupertino = FontLoader('packages/cupertino_icons/CupertinoIcons')
      ..addFont(
        rootBundle.load('packages/cupertino_icons/assets/CupertinoIcons.ttf'),
      );
    await cupertino.load();
  });

  // Signed in + already onboarded, with representative seeded content.
  overrides() => [
    authRepositoryProvider.overrideWithValue(
      FakeAuthRepository(const AuthUser(id: 'shot', email: 'you@example.com')),
    ),
    onboardingSeedProvider.overrideWithValue(true),
    profileRepositoryProvider.overrideWithValue(FakeProfileRepository()),
    sessionApiProvider.overrideWithValue(const NoopSessionApi()),
    sessionChannelProvider.overrideWithValue(FakeSessionChannel()),
    economyChannelProvider.overrideWithValue(FakeEconomyChannel()),
    presenceChannelProvider.overrideWithValue(FakePresenceChannel()),
    notificationChannelProvider.overrideWithValue(FakeNotificationChannel()),
    essentialsRepositoryProvider.overrideWithValue(
      FakeEssentialsRepository([
        const Essential(
          id: 'e1',
          slot: 1,
          title: 'finish the proposal draft',
          targetPomodoros: 3,
          completedPomodoros: 2,
        ),
        Essential(
          id: 'e2',
          slot: 2,
          title: 'review pull requests',
          targetPomodoros: 2,
          completedPomodoros: 2,
          completedAt: DateTime.utc(2026),
        ),
        const Essential(
          id: 'e3',
          slot: 3,
          title: 'a walk after lunch',
          targetPomodoros: 1,
        ),
      ]),
    ),
  ];

  final screens = <String, Widget Function()>{
    'today': () => ProviderScope(
      overrides: overrides(),
      child: Consumer(
        builder: (context, ref, _) => MaterialApp.router(
          debugShowCheckedModeBanner: false,
          theme: buildLullTheme(Brightness.light),
          darkTheme: buildLullTheme(Brightness.dark),
          themeMode: ThemeMode.dark,
          routerConfig: ref.watch(appRouterProvider),
        ),
      ),
    ),
    'focus': () => ProviderScope(
      overrides: overrides(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        darkTheme: buildLullTheme(Brightness.dark),
        themeMode: ThemeMode.dark,
        theme: buildLullTheme(Brightness.light),
        home: const FocusScreen(),
      ),
    ),
    'stats': () => ProviderScope(
      overrides: [
        statsRepositoryProvider.overrideWithValue(FakeStatsRepository()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        darkTheme: buildLullTheme(Brightness.dark),
        themeMode: ThemeMode.dark,
        theme: buildLullTheme(Brightness.light),
        home: const StatsScreen(),
      ),
    ),
    'signin': () => const ProviderScope(child: _SignInApp()),
  };

  for (final MapEntry(key: name, value: build) in screens.entries) {
    for (final MapEntry(key: device, value: spec) in _devices.entries) {
      testWidgets('$name · $device', (tester) async {
        tester.view.physicalSize = spec.size * spec.dpr;
        tester.view.devicePixelRatio = spec.dpr;
        addTearDown(tester.view.reset);

        debugDisableShadows = false;
        try {
          await tester.pumpWidget(build());
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 700));
          await tester.pump(const Duration(milliseconds: 700));
          await expectLater(
            find.byType(MaterialApp),
            matchesGoldenFile('../../../store/screenshots/${name}_$device.png'),
          );
        } finally {
          debugDisableShadows = true;
        }
      });
    }
  }
}

class _SignInApp extends StatelessWidget {
  const _SignInApp();

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: buildLullTheme(Brightness.light),
    darkTheme: buildLullTheme(Brightness.dark),
    themeMode: ThemeMode.dark,
    home: const SignInScreen(),
  );
}
