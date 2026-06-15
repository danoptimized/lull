import 'package:lull/features/notifications/data/devices_repository.dart';
import 'package:lull/features/notifications/domain/notification_category.dart';

/// In-memory [DevicesRepository] for tests — never touches Supabase.
class FakeDevicesRepository implements DevicesRepository {
  final Set<String> devices = <String>{};
  final Map<String, String> tokens = <String, String>{};
  final Map<String, DeviceNotificationPrefs> prefs =
      <String, DeviceNotificationPrefs>{};

  String _key(String userId, String deviceId) => '$userId|$deviceId';

  @override
  Future<void> ensureDevice({
    required String userId,
    required String deviceId,
    required String platform,
  }) async => devices.add(_key(userId, deviceId));

  @override
  Future<void> attachToken({
    required String userId,
    required String deviceId,
    required String token,
  }) async => tokens[_key(userId, deviceId)] = token;

  @override
  Future<DeviceNotificationPrefs> loadPrefs({
    required String userId,
    required String deviceId,
  }) async =>
      prefs[_key(userId, deviceId)] ?? const DeviceNotificationPrefs();

  @override
  Future<void> setCategory({
    required String userId,
    required String deviceId,
    required String platform,
    required NotificationCategory category,
    required bool enabled,
  }) async {
    final key = _key(userId, deviceId);
    devices.add(key);
    prefs[key] = (prefs[key] ?? const DeviceNotificationPrefs()).withCategory(
      category,
      enabled,
    );
  }
}
