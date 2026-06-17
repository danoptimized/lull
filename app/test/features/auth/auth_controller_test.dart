import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lull/features/auth/application/auth_controller.dart';
import 'package:lull/features/auth/data/auth_repository.dart';
import 'package:lull/features/auth/domain/auth_user.dart';

import '../../support/fake_auth_repository.dart';

void main() {
  ProviderContainer containerFor(AuthUser? user) {
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(FakeAuthRepository(user)),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  test('deleteAccount clears the session (router will redirect)', () async {
    final container = containerFor(const AuthUser(id: 'u1'));
    expect(container.read(authControllerProvider)?.id, 'u1');
    expect(container.read(isAuthenticatedProvider), isTrue);

    await container.read(authControllerProvider.notifier).deleteAccount();
    await Future<void>.delayed(Duration.zero); // let the auth stream propagate

    expect(container.read(authControllerProvider), isNull);
    expect(container.read(isAuthenticatedProvider), isFalse);
  });

  test('signOut clears the session', () async {
    final container = containerFor(const AuthUser(id: 'u1'));
    await container.read(authControllerProvider.notifier).signOut();
    await Future<void>.delayed(Duration.zero);
    expect(container.read(authControllerProvider), isNull);
  });

  test('signInWithGoogle establishes a session', () async {
    final container = containerFor(null);
    expect(container.read(authControllerProvider), isNull);

    await container.read(authControllerProvider.notifier).signInWithGoogle();
    await Future<void>.delayed(Duration.zero); // let the auth stream propagate

    expect(container.read(authControllerProvider)?.id, 'fake-google');
  });
}
