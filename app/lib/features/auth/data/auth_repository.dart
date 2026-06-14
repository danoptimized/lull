import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lull/features/auth/domain/auth_user.dart';
// Supabase ships its own AuthUser; ours is the app-facing identity.
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthUser;

/// The auth surface the app depends on. Production talks to Supabase; tests
/// swap in a fake so nothing touches gotrue or the network.
abstract class AuthRepository {
  AuthUser? get currentUser;

  /// Emits on every sign-in / sign-out / token refresh.
  Stream<AuthUser?> userChanges();

  /// Email one-time passcode flow: request a code, then verify it.
  Future<void> sendEmailOtp(String email);
  Future<void> verifyEmailOtp({required String email, required String token});

  Future<void> signOut();
}

class SupabaseAuthRepository implements AuthRepository {
  // Accessed lazily so constructing the repository never requires Supabase to
  // be initialized (it isn't, in tests that override this provider).
  SupabaseClient get _client => Supabase.instance.client;

  AuthUser? _map(User? user) =>
      user == null ? null : AuthUser(id: user.id, email: user.email);

  @override
  AuthUser? get currentUser => _map(_client.auth.currentUser);

  @override
  Stream<AuthUser?> userChanges() =>
      _client.auth.onAuthStateChange.map((state) => _map(state.session?.user));

  @override
  Future<void> sendEmailOtp(String email) =>
      _client.auth.signInWithOtp(email: email, shouldCreateUser: true);

  @override
  Future<void> verifyEmailOtp({
    required String email,
    required String token,
  }) async {
    await _client.auth.verifyOTP(
      email: email,
      token: token,
      type: OtpType.email,
    );
  }

  @override
  Future<void> signOut() => _client.auth.signOut();
}

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => SupabaseAuthRepository(),
);
