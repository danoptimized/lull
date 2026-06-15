import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lull/core/util/device_id.dart';
import 'package:lull/features/auth/application/auth_controller.dart';
import 'package:lull/features/notifications/data/devices_repository.dart';
import 'package:lull/features/notifications/data/push_tokens.dart';
import 'package:lull/features/notifications/domain/notification_category.dart';

/// The platform tag stored on a device row — one of the four the schema allows.
String currentPlatformTag() {
  if (kIsWeb) return 'web';
  return switch (defaultTargetPlatform) {
    TargetPlatform.iOS => 'ios',
    TargetPlatform.android => 'android',
    TargetPlatform.macOS => 'macos',
    _ => 'web',
  };
}

/// Ensure the device row exists, then request + attach the FCM token. Awaitable
/// and side-effect-only (easy to test). Never throws — push is best-effort.
Future<void> registerDevice({
  required DevicesRepository repo,
  required PushTokens tokens,
  required String userId,
  required String deviceId,
  required String platform,
}) async {
  try {
    await repo.ensureDevice(
      userId: userId,
      deviceId: deviceId,
      platform: platform,
    );
    final token = await tokens.requestToken();
    if (token != null) {
      await repo.attachToken(userId: userId, deviceId: deviceId, token: token);
    }
  } catch (error, stack) {
    debugPrint('lull · device registration skipped: $error\n$stack');
  }
}

/// Activated by being watched somewhere in the authed shell. On sign-in it
/// registers this device for push and keeps the token fresh; disposes on
/// sign-out.
final deviceRegistrationProvider = Provider<void>((ref) {
  final user = ref.watch(authControllerProvider);
  if (user == null) return;

  final deviceId = ref.read(deviceIdProvider);
  final repo = ref.read(devicesRepositoryProvider);
  final tokens = ref.read(pushTokensProvider);

  unawaited(
    registerDevice(
      repo: repo,
      tokens: tokens,
      userId: user.id,
      deviceId: deviceId,
      platform: currentPlatformTag(),
    ),
  );

  final sub = tokens.onTokenRefresh.listen((token) {
    repo.attachToken(userId: user.id, deviceId: deviceId, token: token);
  });
  ref.onDispose(sub.cancel);
});

/// This device's per-category notification opt-ins, for the settings UI.
class DevicePrefsController extends AsyncNotifier<DeviceNotificationPrefs> {
  @override
  Future<DeviceNotificationPrefs> build() async {
    final user = ref.watch(authControllerProvider);
    if (user == null) return const DeviceNotificationPrefs();
    return ref
        .read(devicesRepositoryProvider)
        .loadPrefs(userId: user.id, deviceId: ref.read(deviceIdProvider));
  }

  Future<void> toggle(NotificationCategory category, bool enabled) async {
    final user = ref.read(authControllerProvider);
    if (user == null) return;
    final current = state.value ?? const DeviceNotificationPrefs();
    state = AsyncData(current.withCategory(category, enabled)); // optimistic
    await ref
        .read(devicesRepositoryProvider)
        .setCategory(
          userId: user.id,
          deviceId: ref.read(deviceIdProvider),
          platform: currentPlatformTag(),
          category: category,
          enabled: enabled,
        );
  }
}

final devicePrefsControllerProvider =
    AsyncNotifierProvider<DevicePrefsController, DeviceNotificationPrefs>(
      DevicePrefsController.new,
    );
