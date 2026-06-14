import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lull/features/auth/data/auth_repository.dart';
import 'package:lull/features/auth/domain/auth_user.dart';
import 'package:lull/features/notifications/application/notifications_controller.dart';
import 'package:lull/features/notifications/data/notification_channel.dart';
import 'package:lull/features/notifications/domain/app_notification.dart';

import '../support/fake_auth_repository.dart';
import '../support/fake_realtime.dart';

void main() {
  test('collects broadcasts newest-first and tracks unread', () async {
    final inbox = StreamController<AppNotification>.broadcast();
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(
          FakeAuthRepository(const AuthUser(id: 'u')),
        ),
        notificationChannelProvider.overrideWithValue(
          FakeNotificationChannel(inbox.stream),
        ),
      ],
    );
    addTearDown(container.dispose);
    addTearDown(inbox.close);

    expect(container.read(notificationsProvider).unread, 0);

    inbox.add(
      AppNotification(
        category: 'rewards',
        title: 'badge earned',
        body: 'first light',
        createdAt: DateTime.utc(2026),
      ),
    );
    inbox.add(
      AppNotification(
        category: 'rewards',
        title: 'all three, done',
        body: '',
        createdAt: DateTime.utc(2026, 1, 1, 1),
      ),
    );
    await Future<void>.delayed(Duration.zero);

    final state = container.read(notificationsProvider);
    expect(state.items.length, 2);
    expect(state.items.first.title, 'all three, done'); // newest first
    expect(state.unread, 2);

    container.read(notificationsProvider.notifier).markAllRead();
    expect(container.read(notificationsProvider).unread, 0);
    expect(container.read(notificationsProvider).items.length, 2);
  });
}
