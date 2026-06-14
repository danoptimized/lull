import 'dart:async';

import 'package:lull/features/pomodoro/data/session_channel.dart';
import 'package:lull/features/pomodoro/domain/remote_session.dart';

/// In-memory [SessionChannel] for tests and goldens. Defaults to an empty
/// stream (no mirror); pass a stream to drive mirror states.
class FakeSessionChannel implements SessionChannel {
  FakeSessionChannel([Stream<RemoteSession?>? stream])
    : _stream = stream ?? const Stream<RemoteSession?>.empty();

  final Stream<RemoteSession?> _stream;

  @override
  Stream<RemoteSession?> watch({
    required String userId,
    required String myDeviceId,
  }) => _stream;
}
