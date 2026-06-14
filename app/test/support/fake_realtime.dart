import 'dart:async';

import 'package:lull/features/notifications/data/notification_channel.dart';
import 'package:lull/features/notifications/domain/app_notification.dart';
import 'package:lull/features/pomodoro/data/presence_channel.dart';
import 'package:lull/features/stats/data/economy_channel.dart';

/// No-op economy channel for tests — never emits remote changes.
class FakeEconomyChannel implements EconomyChannel {
  @override
  Stream<void> changes(String userId) => const Stream<void>.empty();
}

/// Presence channel reporting a single online device (this one).
class FakePresenceChannel implements PresenceChannel {
  @override
  Stream<int> onlineDevices({
    required String userId,
    required String deviceId,
    required String platform,
  }) => Stream<int>.value(1);
}

/// Notification channel — defaults to an empty stream; pass one to drive
/// notifications in tests.
class FakeNotificationChannel implements NotificationChannel {
  FakeNotificationChannel([Stream<AppNotification>? stream])
    : _stream = stream ?? const Stream<AppNotification>.empty();

  final Stream<AppNotification> _stream;

  @override
  Stream<AppNotification> watch(String userId) => _stream;
}
