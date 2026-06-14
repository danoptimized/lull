import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:lull/core/config/app_prefs.dart';
import 'package:lull/core/theme/theme.dart';
import 'package:lull/features/auth/application/auth_controller.dart';
import 'package:lull/features/auth/presentation/sign_in_screen.dart';
import 'package:lull/features/essentials/presentation/today_screen.dart';
import 'package:lull/features/pomodoro/presentation/focus_screen.dart';
import 'package:lull/features/settings/presentation/settings_screen.dart';
import 'package:lull/features/stats/presentation/stats_screen.dart';
import 'package:lull/ui/components/lull_shell.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

/// Navigation tree.
///
/// Sign-in gates everything: unauthenticated users are redirected to
/// `/sign-in`. The three tabs live in an indexed-stack shell so their state
/// survives switching; `/focus` registers on the root navigator so it pushes
/// full-bleed over the shell (the focus screen is the hero — no nav chrome).
final appRouterProvider = Provider<GoRouter>((ref) {
  final isAuthed = ref.watch(isAuthenticatedProvider);
  final router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/today',
    redirect: (context, state) {
      final atSignIn = state.matchedLocation == '/sign-in';
      if (!isAuthed) return atSignIn ? null : '/sign-in';
      if (atSignIn) return '/today';
      return null;
    },
    routes: [
      GoRoute(
        path: '/sign-in',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const SignInScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            LullShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/today',
                builder: (context, state) => const TodayScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/stats',
                builder: (context, state) => const StatsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/settings',
                builder: (context, state) => const SettingsScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/focus',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) {
          final motion = context.motion;
          // Reduced motion (OS or in-app): functional changes snap, so the
          // push lands with no fade and no scale settle. Read, not watch —
          // re-evaluated on every navigation, which is fresh enough.
          final reduce =
              MediaQuery.disableAnimationsOf(context) ||
              ProviderScope.containerOf(context).read(reducedMotionProvider);
          return CustomTransitionPage<void>(
            key: state.pageKey,
            transitionDuration: reduce ? Duration.zero : motion.calm,
            reverseTransitionDuration: reduce ? Duration.zero : motion.calm,
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  if (reduce) {
                    return child;
                  }
                  // Fade + a barely-there scale settle. Never bounce.
                  final eased = CurvedAnimation(
                    parent: animation,
                    curve: motion.gentleOut,
                  );
                  return FadeTransition(
                    opacity: eased,
                    child: ScaleTransition(
                      scale: Tween<double>(
                        begin: 0.98,
                        end: 1.0,
                      ).animate(eased),
                      child: child,
                    ),
                  );
                },
            child: const FocusScreen(),
          );
        },
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});
