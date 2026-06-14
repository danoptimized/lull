// Design-review screenshots, generated as golden files.
//
// Not part of the default suite (see dart_test.yaml — the `preview` tag is
// skipped unless explicitly requested). Regenerate with:
//
//   flutter test --update-goldens --run-skipped -t preview test/preview
//
// The PNGs land in test/preview/goldens/ at logical resolution.
@Tags(['preview'])
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
import 'package:lull/features/pomodoro/presentation/focus_screen.dart';
import 'package:lull/features/profile/data/profile_repository.dart';
import 'package:lull/features/stats/data/stats_repository.dart';
import 'package:lull/features/stats/presentation/stats_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/fake_auth_repository.dart';
import '../support/fake_essentials_repository.dart';
import '../support/fake_profile_repository.dart';
import '../support/fake_stats_repository.dart';

/// Logical sizes; everything is captured at DPR 2.
const _sizes = <String, Size>{
  'phone': Size(390, 844),
  'desktop': Size(1280, 800),
};

const _themes = <String, ThemeMode>{
  'dark': ThemeMode.dark,
  'light': ThemeMode.light,
};

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});

    // Real Manrope, not Ahem boxes: feed every weight into the test font
    // registry under the family name the theme uses.
    final manrope = FontLoader('Manrope');
    for (final weight in const [300, 400, 500, 600, 700, 800]) {
      final bytes = File('assets/fonts/Manrope-$weight.ttf').readAsBytesSync();
      manrope.addFont(Future.value(ByteData.sublistView(bytes)));
    }
    await manrope.load();

    // Icon fonts too, or every chevron/check renders as a tofu box. Both
    // ship in the unit-test asset bundle, so rootBundle can serve them.
    final material = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await material.load();

    final cupertino = FontLoader('packages/cupertino_icons/CupertinoIcons')
      ..addFont(
        rootBundle.load('packages/cupertino_icons/assets/CupertinoIcons.ttf'),
      );
    await cupertino.load();
  });

  // /focus is legitimately full-bleed (it pushes over the shell on the root
  // navigator), so it is pumped bare. Today renders through the real router
  // so the goldens carry the actual chrome: bottom nav on phone, left rail
  // with the 560px content cap on desktop.
  // A signed-in session with seeded essentials so the gated router lands on
  // the real screens with representative content.
  previewOverrides() => [
    authRepositoryProvider.overrideWithValue(
      FakeAuthRepository(
        const AuthUser(id: 'preview', email: 'you@example.com'),
      ),
    ),
    profileRepositoryProvider.overrideWithValue(FakeProfileRepository()),
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
      ]),
    ),
  ];

  final screens = <String, Widget Function(ThemeMode)>{
    'signin': (themeMode) => ProviderScope(
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: buildLullTheme(Brightness.light),
        darkTheme: buildLullTheme(Brightness.dark),
        themeMode: themeMode,
        home: const SignInScreen(),
      ),
    ),
    'focus': (themeMode) => ProviderScope(
      overrides: previewOverrides(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: buildLullTheme(Brightness.light),
        darkTheme: buildLullTheme(Brightness.dark),
        themeMode: themeMode,
        home: const FocusScreen(),
      ),
    ),
    'today': (themeMode) => ProviderScope(
      overrides: previewOverrides(),
      child: Consumer(
        builder: (context, ref, _) => MaterialApp.router(
          debugShowCheckedModeBanner: false,
          theme: buildLullTheme(Brightness.light),
          darkTheme: buildLullTheme(Brightness.dark),
          themeMode: themeMode,
          routerConfig: ref.watch(appRouterProvider),
        ),
      ),
    ),
    'stats': (themeMode) => ProviderScope(
      overrides: [
        statsRepositoryProvider.overrideWithValue(FakeStatsRepository()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: buildLullTheme(Brightness.light),
        darkTheme: buildLullTheme(Brightness.dark),
        themeMode: themeMode,
        home: const StatsScreen(),
      ),
    ),
  };

  for (final MapEntry(key: screenName, value: buildApp) in screens.entries) {
    for (final MapEntry(key: themeName, value: themeMode) in _themes.entries) {
      for (final MapEntry(key: sizeName, value: size) in _sizes.entries) {
        testWidgets('$screenName · $themeName · $sizeName', (tester) async {
          tester.view.physicalSize = size * 2;
          tester.view.devicePixelRatio = 2.0;
          addTearDown(tester.view.reset);

          // Goldens want true soft shadows. The flag must be back to true
          // before the per-test painting invariant check, hence try/finally
          // rather than setUpAll/tearDownAll.
          debugDisableShadows = false;
          try {
            await tester.pumpWidget(buildApp(themeMode));

            // Flush microtasks so async providers (essentials/stats futures)
            // resolve to data, then two calm beats to land the staggered
            // entrances. Fixed pumps only — the breathing loop never settles.
            await tester.pump();
            await tester.pump(const Duration(milliseconds: 700));
            await tester.pump(const Duration(milliseconds: 700));

            await expectLater(
              find.byType(MaterialApp),
              matchesGoldenFile(
                'goldens/${screenName}_${themeName}_$sizeName.png',
              ),
            );
          } finally {
            debugDisableShadows = true;
          }
        });
      }
    }
  }
}
