import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lull/core/config/app_prefs.dart';
import 'package:lull/core/router/app_router.dart';
import 'package:lull/core/theme/theme.dart';

// Built once, lazily — not per LullApp rebuild (full ThemeData construction
// is not cheap and themeMode changes rebuild this widget).
final ThemeData _lightTheme = buildLullTheme(Brightness.light);
final ThemeData _darkTheme = buildLullTheme(Brightness.dark);

class LullApp extends ConsumerWidget {
  const LullApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
