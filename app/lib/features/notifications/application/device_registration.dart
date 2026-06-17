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

  // Ensure the device row exists, but do NOT request push permission here — the
  // OS prompt is deferred until the user opts in by enabling a notification
  // category (see DevicePrefsController.toggle). Asking up front, before any
  // context, is the classic permission anti-pattern.
  unawaited(_ensureDeviceRow(repo, user.id, deviceId));

  // Defensive: subscribing must never throw into the widget build (it powers
  // the authed shell). Web uses the no-op tokens; this guards mobile edge cases.
  try {
    final sub = tokens.onTokenRefresh.listen((token) {
      repo.attachToken(userId: user.id, deviceId: deviceId, token: token);
    });
    ref.onDispose(sub.cancel);
  } catch (error, stack) {
    debugPrint('lull · token-refresh listen skipped: $error\n$stack');
  }
});

Future<void> _ensureDeviceRow(
  DevicesRepository repo,
  String userId,
  String deviceId,
) async {
  try {
    await repo.ensureDevice(
      userId: userId,
      deviceId: deviceId,
      platform: currentPlatformTag(),
    );
  } catch (error, stack) {
    debugPrint('lull · ensureDevice skipped: $error\n$stack');
  }
}

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

    // Enabling a category is the user's opt-in: now is the contextual moment to
    // ask the OS for push permission and capture a token. Idempotent — no
    // re-prompt once granted, and a no-op token if denied (in-app still works).
    if (enabled) {
      unawaited(
        registerDevice(
          repo: ref.read(devicesRepositoryProvider),
          tokens: ref.read(pushTokensProvider),
          userId: user.id,
          deviceId: ref.read(deviceIdProvider),
          platform: currentPlatformTag(),
        ),
      );
    }
  }
}

final devicePrefsControllerProvider =
    AsyncNotifierProvider<DevicePrefsController, DeviceNotificationPrefs>(
      DevicePrefsController.new,
    );
