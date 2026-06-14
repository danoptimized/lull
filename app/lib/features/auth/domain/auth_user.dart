import 'package:flutter/foundation.dart';

/// The minimal identity the app needs. Deliberately not Supabase's `User` —
/// keeping the surface tiny means the rest of the app never imports gotrue,
/// and the auth layer stays trivially fakeable in tests.
@immutable
class AuthUser {
  const AuthUser({required this.id, this.email});

  final String id;
  final String? email;

  @override
  bool operator ==(Object other) =>
      other is AuthUser && other.id == id && other.email == email;

  @override
  int get hashCode => Object.hash(id, email);
}
