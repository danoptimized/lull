import 'package:lull/features/notifications/data/push_tokens.dart';

/// [PushTokens] for tests: returns a fixed token (or null to simulate denied
/// permission / no APNs / no VAPID).
class FakePushTokens implements PushTokens {
  FakePushTokens({this.token = 'fcm-test-token'});

  final String? token;

  @override
  Future<String?> requestToken() async => token;

  @override
  Stream<String> get onTokenRefresh => const Stream<String>.empty();
}
