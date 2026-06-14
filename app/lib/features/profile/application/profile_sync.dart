import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lull/core/config/app_prefs.dart';
import 'package:lull/features/profile/data/profile_repository.dart';

ThemeMode _parseThemeMode(String? value) => switch (value) {
  'light' => ThemeMode.light,
  'dark' => ThemeMode.dark,
  _ => ThemeMode.system,
};

/// Bridges the app-local theme / reduced-motion preferences with the signed-in
/// user's profile: loads the stored values once, then writes any change back so
/// settings follow the account across devices.
///
/// Watched only from authenticated screens, so it never runs — or touches the
/// backend — while signed out. Reads are defensive: offline simply keeps the
/// local defaults.
final profileSyncProvider = Provider<void>((ref) {
  final repo = ref.watch(profileRepositoryProvider);

  Future<void> load() async {
    try {
      final row = await repo.fetch();
      if (row == null) return;
      ref
          .read(themeModeProvider.notifier)
          .set(_parseThemeMode(row['theme_mode'] as String?));
      ref
          .read(reducedMotionProvider.notifier)
          .set((row['reduced_motion'] as bool?) ?? false);
    } catch (_) {
      // Offline or no profile yet — keep local defaults.
    }
  }

  load();

  ref.listen<ThemeMode>(themeModeProvider, (previous, next) {
    if (previous != next) repo.updatePrefs(themeMode: next.name).ignore();
  });
  ref.listen<bool>(reducedMotionProvider, (previous, next) {
    if (previous != next) repo.updatePrefs(reducedMotion: next).ignore();
  });
});
