import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lull/core/util/device_id.dart';
import 'package:lull/features/auth/application/auth_controller.dart';
import 'package:lull/features/pomodoro/data/session_channel.dart';
import 'package:lull/features/pomodoro/domain/remote_session.dart';

/// The session running on another of the user's devices, live. Null when none —
/// the UI shows the mirror card only when this is present.
final mirroredSessionProvider = StreamProvider<RemoteSession?>((ref) {
  final user = ref.watch(authControllerProvider);
  if (user == null) return Stream<RemoteSession?>.value(null);
  final deviceId = ref.watch(deviceIdProvider);
  return ref
      .watch(sessionChannelProvider)
      .watch(userId: user.id, myDeviceId: deviceId);
});
