import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Whether tactile feedback is on, persisted across launches.
class HapticsEnabledNotifier extends Notifier<bool> {
  static const String _key = 'lull.haptics_enabled.v1';

  @override
  bool build() {
    unawaited(_restore());
    return true;
  }

  void set(bool value) {
    state = value;
    unawaited(_persist(value));
  }

  Future<void> _restore() async {
    try {
      final value = (await SharedPreferences.getInstance()).getBool(_key);
      if (value != null) state = value;
    } catch (_) {
      // No prefs plugin (tests without mock values) — keep the default.
    }
  }

  Future<void> _persist(bool value) async {
    try {
      await (await SharedPreferences.getInstance()).setBool(_key, value);
    } catch (_) {}
  }
}

final hapticsEnabledProvider = NotifierProvider<HapticsEnabledNotifier, bool>(
  HapticsEnabledNotifier.new,
);

/// Thin facade over [HapticFeedback] that respects the user's preference.
///
/// `HapticFeedback` is already a no-op on platforms without a haptic engine
/// (web, most desktops), so callers never need to branch on platform.
class Haptics {
  const Haptics({required this.enabled});

  final bool enabled;

  /// A light tap — beginning a session.
  void light() {
    if (enabled) HapticFeedback.lightImpact();
  }

  /// A soft selection click — pausing or resuming.
  void selection() {
    if (enabled) HapticFeedback.selectionClick();
  }

  /// A fuller impact — a session completing.
  void success() {
    if (enabled) HapticFeedback.mediumImpact();
  }
}

final hapticsProvider = Provider<Haptics>(
  (ref) => Haptics(enabled: ref.watch(hapticsEnabledProvider)),
);
