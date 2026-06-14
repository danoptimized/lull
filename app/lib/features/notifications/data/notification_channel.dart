import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lull/features/notifications/domain/app_notification.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Streams in-app notifications broadcast to the user's `notify:<uid>` channel.
abstract class NotificationChannel {
  Stream<AppNotification> watch(String userId);
}

class SupabaseNotificationChannel implements NotificationChannel {
  SupabaseClient get _client => Supabase.instance.client;

  @override
  Stream<AppNotification> watch(String userId) {
    final controller = StreamController<AppNotification>();
    RealtimeChannel? channel;

    controller.onListen = () {
      channel = _client
          .channel(
            'notify:$userId',
            opts: const RealtimeChannelConfig(private: true),
          )
          .onBroadcast(
            event: 'notification',
            callback: (payload) {
              final inner = payload['payload'];
              final data = inner is Map<String, dynamic> ? inner : payload;
              try {
                controller.add(AppNotification.fromJson(data, DateTime.now()));
              } catch (_) {}
            },
          )
          .subscribe();
    };
    controller.onCancel = () async {
      final c = channel;
      if (c != null) await _client.removeChannel(c);
    };
    return controller.stream;
  }
}

final notificationChannelProvider = Provider<NotificationChannel>(
  (ref) => SupabaseNotificationChannel(),
);
