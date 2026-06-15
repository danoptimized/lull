import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lull/features/notifications/domain/notification_category.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Reads and writes the caller's `devices` rows. A device is identified by the
/// app's persistent install id (`device_id`), so it keeps one row as its FCM
/// token rotates. RLS scopes every row to the signed-in user.
abstract class DevicesRepository {
  /// Make sure a row exists for this install (no-op on the token/prefs).
  Future<void> ensureDevice({
    required String userId,
    required String deviceId,
    required String platform,
  });

  /// Attach (or refresh) this install's FCM token.
  Future<void> attachToken({
    required String userId,
    required String deviceId,
    required String token,
  });

  Future<DeviceNotificationPrefs> loadPrefs({
    required String userId,
    required String deviceId,
  });

  Future<void> setCategory({
    required String userId,
    required String deviceId,
    required String platform,
    required NotificationCategory category,
    required bool enabled,
  });
}

class SupabaseDevicesRepository implements DevicesRepository {
  SupabaseClient get _client => Supabase.instance.client;

  @override
  Future<void> ensureDevice({
    required String userId,
    required String deviceId,
    required String platform,
  }) async {
    // Upsert only identity columns so an existing token/prefs aren't clobbered.
    await _client.from('devices').upsert({
      'user_id': userId,
      'device_id': deviceId,
      'platform': platform,
      'last_seen_at': DateTime.now().toUtc().toIso8601String(),
    }, onConflict: 'user_id,device_id');
  }

  @override
  Future<void> attachToken({
    required String userId,
    required String deviceId,
    required String token,
  }) async {
    await _client
        .from('devices')
        .update({
          'push_token': token,
          'token_updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('user_id', userId)
        .eq('device_id', deviceId);
  }

  @override
  Future<DeviceNotificationPrefs> loadPrefs({
    required String userId,
    required String deviceId,
  }) async {
    final row = await _client
        .from('devices')
        .select('notify_timer, notify_essentials, notify_streak, notify_rewards')
        .eq('user_id', userId)
        .eq('device_id', deviceId)
        .maybeSingle();
    if (row == null) return const DeviceNotificationPrefs();
    return DeviceNotificationPrefs(
      timer: row['notify_timer'] as bool? ?? true,
      essentials: row['notify_essentials'] as bool? ?? true,
      streak: row['notify_streak'] as bool? ?? true,
      rewards: row['notify_rewards'] as bool? ?? true,
    );
  }

  @override
  Future<void> setCategory({
    required String userId,
    required String deviceId,
    required String platform,
    required NotificationCategory category,
    required bool enabled,
  }) async {
    // Upsert so prefs are editable even before a token is attached.
    await _client.from('devices').upsert({
      'user_id': userId,
      'device_id': deviceId,
      'platform': platform,
      category.column: enabled,
    }, onConflict: 'user_id,device_id');
  }
}

final devicesRepositoryProvider = Provider<DevicesRepository>(
  (ref) => SupabaseDevicesRepository(),
);
