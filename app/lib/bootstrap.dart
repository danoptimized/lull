import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lull/app.dart';
import 'package:lull/core/util/device_id.dart';
import 'package:lull/data/supabase/supabase_config.dart';
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

  await Supabase.initialize(
    url: SupabaseConfig.url,
    publishableKey: SupabaseConfig.publishableKey,
  );

  final deviceId = await DeviceId.loadOrCreate();

  runApp(
    ProviderScope(
      overrides: [deviceIdProvider.overrideWithValue(deviceId)],
      child: const LullApp(),
    ),
  );
}
