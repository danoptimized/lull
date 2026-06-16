import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lull/features/onboarding/application/onboarding.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('seeds its initial value from the boot-time flag', () {
    final c = ProviderContainer(
      overrides: [onboardingSeedProvider.overrideWithValue(true)],
    );
    addTearDown(c.dispose);
    expect(c.read(onboardingSeenProvider), isTrue);
  });

  test('markSeen advances state and persists the flag', () async {
    final c = ProviderContainer(
      overrides: [onboardingSeedProvider.overrideWithValue(false)],
    );
    addTearDown(c.dispose);
    expect(c.read(onboardingSeenProvider), isFalse);

    await c.read(onboardingSeenProvider.notifier).markSeen();

    expect(c.read(onboardingSeenProvider), isTrue);
    expect(
      (await SharedPreferences.getInstance()).getBool(onboardingSeenKey),
      isTrue,
    );
  });
}
