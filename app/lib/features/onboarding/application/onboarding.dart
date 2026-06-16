import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The shared_preferences key for "the first-run welcome has been seen".
const String onboardingSeenKey = 'lull.onboarding_seen.v1';

/// The value loaded once at boot and injected here (see bootstrap), so the
/// router knows synchronously on the first frame whether to show the welcome —
/// no flash of onboarding for a returning user. Defaults to false in tests.
final onboardingSeedProvider = Provider<bool>((_) => false);

/// Whether the user has completed the first-run welcome. Seeded from
/// [onboardingSeedProvider]; [markSeen] persists the flag.
class OnboardingSeen extends Notifier<bool> {
  @override
  bool build() => ref.read(onboardingSeedProvider);

  Future<void> markSeen() async {
    state = true;
    try {
      await (await SharedPreferences.getInstance()).setBool(
        onboardingSeenKey,
        true,
      );
    } catch (_) {
      // No prefs plugin (tests) — the in-memory flag still advances the router.
    }
  }
}

final onboardingSeenProvider = NotifierProvider<OnboardingSeen, bool>(
  OnboardingSeen.new,
);
