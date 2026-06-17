import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lull/features/auth/data/auth_repository.dart';
import 'package:lull/features/auth/domain/auth_user.dart';

/// Holds the current signed-in user (or null), kept in sync with the auth
/// backend's change stream. The router watches [isAuthenticatedProvider] to
/// gate the app.
class AuthController extends Notifier<AuthUser?> {
  @override
  AuthUser? build() {
    final repo = ref.watch(authRepositoryProvider);
    final sub = repo.userChanges().listen((user) => state = user);
    ref.onDispose(sub.cancel);
    return repo.currentUser;
  }

  Future<void> sendOtp(String email) =>
      ref.read(authRepositoryProvider).sendEmailOtp(email.trim());

  Future<void> verifyOtp({required String email, required String token}) => ref
      .read(authRepositoryProvider)
      .verifyEmailOtp(email: email.trim(), token: token.trim());

  Future<void> signInWithGoogle() =>
      ref.read(authRepositoryProvider).signInWithGoogle();

  Future<void> signOut() => ref.read(authRepositoryProvider).signOut();

  Future<void> deleteAccount() =>
      ref.read(authRepositoryProvider).deleteAccount();
}

final authControllerProvider = NotifierProvider<AuthController, AuthUser?>(
  AuthController.new,
);

final isAuthenticatedProvider = Provider<bool>(
  (ref) => ref.watch(authControllerProvider) != null,
);
