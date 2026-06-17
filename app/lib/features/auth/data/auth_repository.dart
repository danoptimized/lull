import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lull/features/auth/domain/auth_user.dart';
// Supabase ships its own AuthUser; ours is the app-facing identity.
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthUser;

/// Deep link the OAuth provider returns to on mobile (registered as a custom
/// URL scheme in iOS Info.plist + the Android manifest, and allow-listed in the
/// Supabase dashboard). On web the redirect uses the configured Site URL.
const String _oauthRedirect = 'works.lull://login-callback';

/// The auth surface the app depends on. Production talks to Supabase; tests
/// swap in a fake so nothing touches gotrue or the network.
abstract class AuthRepository {
  AuthUser? get currentUser;

  /// Emits on every sign-in / sign-out / token refresh.
  Stream<AuthUser?> userChanges();

  /// Email one-time passcode flow: request a code, then verify it.
  Future<void> sendEmailOtp(String email);
  Future<void> verifyEmailOtp({required String email, required String token});

  /// Google OAuth — opens the provider; the session arrives via the redirect.
  Future<void> signInWithGoogle();

  Future<void> signOut();

  /// Irreversibly delete the account and all its data, then sign out.
  Future<void> deleteAccount();
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
  Future<void> signInWithGoogle() => _client.auth.signInWithOAuth(
    OAuthProvider.google,
    // Web returns to the current origin (so localhost dev and prod both work,
    // as long as the origin is in Supabase's redirect allowlist); mobile uses
    // the registered custom scheme.
    redirectTo: kIsWeb ? Uri.base.origin : _oauthRedirect,
  );

  @override
  Future<void> signOut() => _client.auth.signOut();

  @override
  Future<void> deleteAccount() async {
    // The server hard-deletes the auth user (cascading all data); then we clear
    // the now-invalid local session, which flips the auth stream to signed-out.
    await _client.functions.invoke('delete-account');
    await _client.auth.signOut();
  }
}

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => SupabaseAuthRepository(),
);
