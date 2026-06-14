import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lull/core/util/device_id.dart';
import 'package:lull/features/auth/application/auth_controller.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// The number of the user's devices currently online, tracked over presence on
/// the user's private channel. Each device contributes one presence keyed by
/// its [DeviceId], so the count is distinct devices.
abstract class PresenceChannel {
  Stream<int> onlineDevices({
    required String userId,
    required String deviceId,
    required String platform,
  });
}

class SupabasePresenceChannel implements PresenceChannel {
  SupabaseClient get _client => Supabase.instance.client;

  @override
  Stream<int> onlineDevices({
    required String userId,
    required String deviceId,
    required String platform,
  }) {
    final controller = StreamController<int>();
    RealtimeChannel? channel;

    void emit() {
      try {
        controller.add(channel?.presenceState().length ?? 1);
      } catch (_) {}
    }

    controller.onListen = () {
      final ch = _client.channel(
        'presence:$userId',
        opts: RealtimeChannelConfig(key: deviceId, private: true),
      );
      channel = ch;
      ch
          .onPresenceSync((_) => emit())
          .onPresenceJoin((_) => emit())
          .onPresenceLeave((_) => emit())
          .subscribe((status, _) async {
            if (status == RealtimeSubscribeStatus.subscribed) {
              await ch.track({'device_id': deviceId, 'platform': platform});
            }
          });
    };
    controller.onCancel = () async {
      final c = channel;
      if (c != null) await _client.removeChannel(c);
    };
    return controller.stream;
  }
}

String currentPlatform() {
  if (kIsWeb) return 'web';
  return defaultTargetPlatform.name;
}

final presenceChannelProvider = Provider<PresenceChannel>(
  (ref) => SupabasePresenceChannel(),
);

/// How many of the user's devices are online right now (1 = just this one).
final onlineDevicesProvider = StreamProvider<int>((ref) {
  final user = ref.watch(authControllerProvider);
  if (user == null) return Stream<int>.value(0);
  final deviceId = ref.watch(deviceIdProvider);
  return ref
      .watch(presenceChannelProvider)
      .onlineDevices(
        userId: user.id,
        deviceId: deviceId,
        platform: currentPlatform(),
      );
});
