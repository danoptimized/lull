import 'dart:ui' show PlatformDispatcher;

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lull/app.dart';
import 'package:lull/core/util/device_id.dart';
import 'package:lull/data/supabase/supabase_config.dart';
import 'package:lull/features/onboarding/application/onboarding.dart';
import 'package:lull/firebase_options.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Single composition root. Later milestones add persistence warm-up and
/// crash reporting here without touching `main`.
Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Minimal error hook: anything escaping the framework gets logged instead
  // of silently killing the isolate. Real reporting lands later.
  PlatformDispatcher.instance.onError = (error, stackTrace) {
    debugPrint('lull · uncaught: $error\n$stackTrace');
    return true;
  };

  // Firebase backs out-of-app push (M6). initializeApp is required before any
  // Firebase plugin (e.g. messaging) is touched; failure here must not block
  // the app, which is fully usable without push.
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (error, stack) {
    debugPrint('lull · Firebase init skipped: $error\n$stack');
  }

  await Supabase.initialize(
    url: SupabaseConfig.url,
    publishableKey: SupabaseConfig.publishableKey,
  );

  final deviceId = await DeviceId.loadOrCreate();
  // Read the first-run flag synchronously at boot so the router never flashes
  // the welcome screen for a returning user.
  final prefs = await SharedPreferences.getInstance();
  final onboardingSeen = prefs.getBool(onboardingSeenKey) ?? false;

  runApp(
    ProviderScope(
      overrides: [
        deviceIdProvider.overrideWithValue(deviceId),
        onboardingSeedProvider.overrideWithValue(onboardingSeen),
      ],
      child: const LullApp(),
    ),
  );
}
