import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The device's push identity. Isolated behind this interface so the rest of the
/// app — and every test — never imports firebase_messaging.
abstract class PushTokens {
  /// Ask the OS for notification permission and return the FCM token, or null
  /// if it's denied or unavailable (simulator without APNs, web without a VAPID
  /// key, etc.). Never throws.
  Future<String?> requestToken();

  /// Emits whenever FCM rotates the token for this install.
  Stream<String> get onTokenRefresh;
}

class FirebasePushTokens implements PushTokens {
  @override
  Future<String?> requestToken() async {
    try {
      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.requestPermission();
      switch (settings.authorizationStatus) {
        case AuthorizationStatus.authorized:
        case AuthorizationStatus.provisional:
          return await messaging.getToken();
        case AuthorizationStatus.denied:
        case AuthorizationStatus.notDetermined:
          return null;
      }
    } catch (_) {
      // No APNs (simulator), no VAPID (web), or Firebase unavailable.
      return null;
    }
  }

  @override
  Stream<String> get onTokenRefresh {
    try {
      return FirebaseMessaging.instance.onTokenRefresh;
    } catch (_) {
      return const Stream<String>.empty();
    }
  }
}

/// For tests and unsupported platforms: no permission prompt, no token.
class NoopPushTokens implements PushTokens {
  const NoopPushTokens();

  @override
  Future<String?> requestToken() async => null;

  @override
  Stream<String> get onTokenRefresh => const Stream.empty();
}

// Web push needs a VAPID key + service worker that aren't set up yet, and the
// firebase_messaging web APIs throw without them — so use the no-op on web.
final pushTokensProvider = Provider<PushTokens>(
  (ref) => kIsWeb ? const NoopPushTokens() : FirebasePushTokens(),
);
