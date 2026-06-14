import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lull/core/util/ids.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A stable per-install id. It tags the sessions this device starts, so a
/// device can tell its own session (including one it rehydrates after a
/// relaunch) apart from one running on another device — which it mirrors.
class DeviceId {
  const DeviceId._();

  static const _key = 'lull.device_id.v1';

  static Future<String> loadOrCreate() async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString(_key);
    if (existing != null) return existing;
    final id = newUuidV4();
    await prefs.setString(_key, id);
    return id;
  }
}

/// Overridden in bootstrap with the persisted id. The fallback (a fresh id per
/// container) is only used in tests, which don't depend on persistence.
final deviceIdProvider = Provider<String>((ref) => newUuidV4());
