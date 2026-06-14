import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Whether tactile feedback is on. App-local in M1; syncs to the profile later.
class HapticsEnabledNotifier extends Notifier<bool> {
  @override
  bool build() => true;

  void set(bool value) => state = value;
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
