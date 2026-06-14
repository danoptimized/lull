import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lull/core/time/server_clock.dart';
import 'package:lull/features/pomodoro/data/session_api.dart';

/// Measures the device-vs-server clock offset once and calibrates the shared
/// [ServerClock], so a mirrored countdown agrees with the device that started
/// the session. Watched by the authenticated app; failure is harmless (the
/// clock simply stays at zero offset and the mirror leans on device time).
final clockSyncProvider = FutureProvider<void>((ref) async {
  final clock = ref.read(serverClockProvider);
  if (clock is! CalibratedServerClock) return;

  final t0 = DateTime.now().toUtc();
  final serverNow = await ref.read(sessionApiProvider).serverTime();
  final t1 = DateTime.now().toUtc();
  if (serverNow == null) return;

  // The device's time at the server's instant ≈ the round-trip midpoint.
  final mid = t0.add(
    Duration(microseconds: t1.difference(t0).inMicroseconds ~/ 2),
  );
  clock.calibrate(serverNow.difference(mid));
});
