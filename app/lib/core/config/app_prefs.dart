import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// App-local preferences, persisted across launches via shared_preferences.
/// Each notifier returns its default synchronously, then restores the saved
/// value (a brief default→saved settle is harmless for these).

class ThemeModeNotifier extends Notifier<ThemeMode> {
  static const String _key = 'lull.theme_mode.v1';

  @override
  ThemeMode build() {
    unawaited(_restore());
    return ThemeMode.system;
  }

  void set(ThemeMode mode) {
    state = mode;
    unawaited(_persist(mode));
  }

  Future<void> _restore() async {
    try {
      final name = (await SharedPreferences.getInstance()).getString(_key);
      final match = ThemeMode.values.where((m) => m.name == name);
      if (match.isNotEmpty) state = match.first;
    } catch (_) {
      // No prefs plugin (tests without mock values) — keep the default.
    }
  }

  Future<void> _persist(ThemeMode mode) async {
    try {
      await (await SharedPreferences.getInstance()).setString(_key, mode.name);
    } catch (_) {}
  }
}

final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(
  ThemeModeNotifier.new,
);

/// App-level reduced-motion override. Motion widgets honour this OR the OS
/// setting ([MediaQuery.disableAnimationsOf]) — whichever asks for less.
class ReducedMotionNotifier extends Notifier<bool> {
  static const String _key = 'lull.reduced_motion.v1';

  @override
  bool build() {
    unawaited(_restore());
    return false;
  }

  void set(bool value) {
    state = value;
    unawaited(_persist(value));
  }

  Future<void> _restore() async {
    try {
      final value = (await SharedPreferences.getInstance()).getBool(_key);
      if (value != null) state = value;
    } catch (_) {}
  }

  Future<void> _persist(bool value) async {
    try {
      await (await SharedPreferences.getInstance()).setBool(_key, value);
    } catch (_) {}
  }
}

final reducedMotionProvider = NotifierProvider<ReducedMotionNotifier, bool>(
  ReducedMotionNotifier.new,
);
