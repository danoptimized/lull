import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Reads and writes the signed-in user's profile row (settings that follow the
/// account across devices). The row itself is created server-side by the
/// signup trigger; this only ever updates it.
abstract class ProfileRepository {
  /// Set `profiles.timezone` to the device's IANA zone if it differs. The day
  /// boundary for essentials and (later) streaks is computed from it, so it
  /// must track the device.
  Future<void> ensureTimezone();

  Future<Map<String, dynamic>?> fetch();

  Future<void> updatePrefs({String? themeMode, bool? reducedMotion});
}

class SupabaseProfileRepository implements ProfileRepository {
  SupabaseClient get _client => Supabase.instance.client;
  String? get _uid => _client.auth.currentUser?.id;

  @override
  Future<void> ensureTimezone() async {
    final uid = _uid;
    if (uid == null) return;
    final info = await FlutterTimezone.getLocalTimezone();
    final tz = info.identifier;
    final row = await _client
        .from('profiles')
        .select('timezone')
        .eq('id', uid)
        .maybeSingle();
    if (row == null || row['timezone'] != tz) {
      await _client.from('profiles').update({'timezone': tz}).eq('id', uid);
    }
  }

  @override
  Future<Map<String, dynamic>?> fetch() async {
    final uid = _uid;
    if (uid == null) return null;
    return _client.from('profiles').select().eq('id', uid).maybeSingle();
  }

  @override
  Future<void> updatePrefs({String? themeMode, bool? reducedMotion}) async {
    final uid = _uid;
    if (uid == null) return;
    final patch = <String, dynamic>{};
    if (themeMode != null) patch['theme_mode'] = themeMode;
    if (reducedMotion != null) patch['reduced_motion'] = reducedMotion;
    if (patch.isEmpty) return;
    await _client.from('profiles').update(patch).eq('id', uid);
  }
}

final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => SupabaseProfileRepository(),
);
