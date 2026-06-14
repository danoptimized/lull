import 'package:lull/features/profile/data/profile_repository.dart';

/// No-op [ProfileRepository] for tests — never touches Supabase.
class FakeProfileRepository implements ProfileRepository {
  @override
  Future<void> ensureTimezone() async {}

  @override
  Future<Map<String, dynamic>?> fetch() async => null;

  @override
  Future<void> updatePrefs({String? themeMode, bool? reducedMotion}) async {}
}
