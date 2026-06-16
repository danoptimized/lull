import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// App-local theme / reduced-motion state.
///
/// These are intentionally NOT persisted to local storage here: for a signed-in
/// user they are loaded from and written back to the account profile by
/// `profileSyncProvider`, so the settings follow the account across devices. A
/// second local store would race that sync and could push a stale device-local
/// value back to the server. (Device-only prefs — soundscape/sfx/haptics — are
/// persisted locally in their own controllers, since they aren't in the profile.)

class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => ThemeMode.system;

  void set(ThemeMode mode) => state = mode;
}

final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(
  ThemeModeNotifier.new,
);

/// App-level reduced-motion override. Motion widgets honour this OR the OS
/// setting ([MediaQuery.disableAnimationsOf]) — whichever asks for less.
class ReducedMotionNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void set(bool value) => state = value;
}

final reducedMotionProvider = NotifierProvider<ReducedMotionNotifier, bool>(
  ReducedMotionNotifier.new,
);
