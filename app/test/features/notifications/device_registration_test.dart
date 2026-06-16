import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lull/core/util/device_id.dart';
import 'package:lull/features/auth/data/auth_repository.dart';
import 'package:lull/features/auth/domain/auth_user.dart';
import 'package:lull/features/notifications/application/device_registration.dart';
import 'package:lull/features/notifications/data/devices_repository.dart';
import 'package:lull/features/notifications/data/push_tokens.dart';
import 'package:lull/features/notifications/domain/notification_category.dart';

import '../../support/fake_auth_repository.dart';
import '../../support/fake_devices_repository.dart';
import '../../support/fake_push_tokens.dart';

void main() {
  test('registerDevice ensures a row and attaches the token', () async {
    final repo = FakeDevicesRepository();
    await registerDevice(
      repo: repo,
      tokens: FakePushTokens(),
      userId: 'u1',
      deviceId: 'd1',
      platform: 'ios',
    );
    expect(repo.devices.contains('u1|d1'), isTrue);
    expect(repo.tokens['u1|d1'], 'fcm-test-token');
  });

  test('registerDevice with no token still ensures the row', () async {
    final repo = FakeDevicesRepository();
    await registerDevice(
      repo: repo,
      tokens: FakePushTokens(token: null), // denied / no APNs / no VAPID
      userId: 'u1',
      deviceId: 'd1',
      platform: 'web',
    );
    expect(repo.devices.contains('u1|d1'), isTrue);
    expect(repo.tokens.containsKey('u1|d1'), isFalse);
  });

  test('DevicePrefsController loads defaults and persists a toggle', () async {
    final repo = FakeDevicesRepository();
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(
          FakeAuthRepository(const AuthUser(id: 'u1')),
        ),
        deviceIdProvider.overrideWithValue('d1'),
        devicesRepositoryProvider.overrideWithValue(repo),
      ],
    );
    addTearDown(container.dispose);

    final prefs = await container.read(devicePrefsControllerProvider.future);
    expect(prefs.rewards, isTrue, reason: 'defaults all on');

    await container
        .read(devicePrefsControllerProvider.notifier)
        .toggle(NotificationCategory.rewards, false);

    expect(repo.prefs['u1|d1']?.rewards, isFalse, reason: 'persisted to repo');
    expect(
      container.read(devicePrefsControllerProvider).value?.rewards,
      isFalse,
      reason: 'reflected in state',
    );
  });

  test('enabling a category requests + attaches a push token (opt-in)', () async {
    final repo = FakeDevicesRepository();
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(
          FakeAuthRepository(const AuthUser(id: 'u1')),
        ),
        deviceIdProvider.overrideWithValue('d1'),
        devicesRepositoryProvider.overrideWithValue(repo),
        pushTokensProvider.overrideWithValue(FakePushTokens()),
      ],
    );
    addTearDown(container.dispose);

    await container.read(devicePrefsControllerProvider.future);
    await container
        .read(devicePrefsControllerProvider.notifier)
        .toggle(NotificationCategory.timer, true);
    await Future<void>.delayed(const Duration(milliseconds: 20)); // fire-and-forget

    expect(repo.tokens['u1|d1'], 'fcm-test-token', reason: 'token captured');
  });
}
