import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Server-authoritative time.
///
/// Stub seam for the M5 skew service: once lull talks to a backend, the
/// implementation behind [serverClockProvider] will measure device-vs-server
/// drift and expose corrected time so anchored timers agree across devices.
/// Until then, [SystemServerClock] reports device time with zero skew —
/// callers can already depend on this interface today.
abstract class ServerClock {
  /// Current time, corrected for the measured [skew].
  DateTime now();

  /// Estimated `device clock - server clock` offset.
  Duration get skew;
}

/// M0 implementation: trusts the device clock entirely.
class SystemServerClock implements ServerClock {
  const SystemServerClock();

  @override
  DateTime now() => DateTime.now();

  @override
  Duration get skew => Duration.zero;
}

final serverClockProvider = Provider<ServerClock>(
  (ref) => const SystemServerClock(),
);
