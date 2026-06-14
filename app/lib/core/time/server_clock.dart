import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Server-authoritative time.
///
/// Anchored timers and the cross-device mirror both reason in *server* time:
/// the owner stamps a session against this clock, and a watching device
/// computes the same countdown from the broadcast anchor. [CalibratedServerClock]
/// carries a measured device-vs-server offset so those two devices agree even
/// if their wall clocks don't.
abstract class ServerClock {
  /// Current time in UTC, corrected by the measured [skew].
  DateTime now();

  /// Estimated `server clock - device clock` offset.
  Duration get skew;
}

/// Trusts the device clock entirely (offset zero). Used in tests.
class SystemServerClock implements ServerClock {
  const SystemServerClock();

  @override
  DateTime now() => DateTime.now().toUtc();

  @override
  Duration get skew => Duration.zero;
}

/// Applies a measured offset to the device clock. The offset is set once the
/// app measures it against the server (see clock_sync.dart) and can be updated
/// any time without rebuilding dependents.
class CalibratedServerClock implements ServerClock {
  Duration _offset = Duration.zero;

  void calibrate(Duration offset) => _offset = offset;

  @override
  DateTime now() => DateTime.now().toUtc().add(_offset);

  @override
  Duration get skew => _offset;
}

final serverClockProvider = Provider<ServerClock>(
  (ref) => CalibratedServerClock(),
);
