import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lull/core/config/app_prefs.dart';
import 'package:lull/core/router/app_router.dart';
import 'package:lull/core/theme/theme.dart';
import 'package:lull/features/auth/application/auth_controller.dart';
import 'package:lull/features/essentials/application/essentials_controller.dart';

// Built once, lazily — not per LullApp rebuild (full ThemeData construction
// is not cheap and themeMode changes rebuild this widget).
final ThemeData _lightTheme = buildLullTheme(Brightness.light);
final ThemeData _darkTheme = buildLullTheme(Brightness.dark);

class LullApp extends ConsumerStatefulWidget {
  const LullApp({super.key});

  @override
  ConsumerState<LullApp> createState() => _LullAppState();
}

class _LullAppState extends ConsumerState<LullApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // On returning to the app, re-sync essentials — this drains any offline
    // outbox edits even if the user doesn't touch the list. Guarded by auth so
    // it never builds the controller (which needs a user) while signed out.
    if (state == AppLifecycleState.resumed &&
        ref.read(authControllerProvider) != null) {
      ref.read(essentialsControllerProvider.notifier).refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'lull',
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      theme: _lightTheme,
      darkTheme: _darkTheme,
      themeMode: themeMode,
    );
  }
}
