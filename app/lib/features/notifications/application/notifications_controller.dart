import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lull/features/auth/application/auth_controller.dart';
import 'package:lull/features/notifications/data/notification_channel.dart';
import 'package:lull/features/notifications/domain/app_notification.dart';

@immutable
class NotificationsState {
  const NotificationsState({this.items = const [], this.unread = 0});

  final List<AppNotification> items;
  final int unread;

  @override
  bool operator ==(Object other) =>
      other is NotificationsState &&
      other.unread == unread &&
      other.items.length == items.length;

  @override
  int get hashCode => Object.hash(unread, items.length);
}

/// Collects in-app notifications from the realtime channel, newest first, and
/// tracks an unread count for the bell badge.
class NotificationsController extends Notifier<NotificationsState> {
  static const _cap = 50;

  @override
  NotificationsState build() {
    final user = ref.watch(authControllerProvider);
    if (user == null) return const NotificationsState();
    final sub = ref.read(notificationChannelProvider).watch(user.id).listen((
      notification,
    ) {
      state = NotificationsState(
        items: [notification, ...state.items].take(_cap).toList(),
        unread: state.unread + 1,
      );
    });
    ref.onDispose(sub.cancel);
    return const NotificationsState();
  }

  void markAllRead() {
    if (state.unread == 0) return;
    state = NotificationsState(items: state.items);
  }
}

final notificationsProvider =
    NotifierProvider<NotificationsController, NotificationsState>(
      NotificationsController.new,
    );
