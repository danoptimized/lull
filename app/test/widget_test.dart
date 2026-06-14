import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lull/app.dart';
import 'package:lull/features/auth/data/auth_repository.dart';
import 'package:lull/features/auth/domain/auth_user.dart';
import 'package:lull/features/essentials/data/essentials_repository.dart';
import 'package:lull/features/essentials/presentation/today_screen.dart';
import 'package:lull/features/profile/data/profile_repository.dart';
import 'package:lull/ui/components/lull_shell.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/fake_auth_repository.dart';
import 'support/fake_essentials_repository.dart';
import 'support/fake_profile_repository.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('lull boots into the today screen when signed in', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(
            FakeAuthRepository(const AuthUser(id: 'test')),
          ),
          essentialsRepositoryProvider.overrideWithValue(
            FakeEssentialsRepository(),
          ),
          profileRepositoryProvider.overrideWithValue(FakeProfileRepository()),
        ],
        child: const LullApp(),
      ),
    );

    // Fixed-duration pumps only — the breathing loop never settles, so
    // pumpAndSettle would time out. A few calm-length frames let the
    // staggered entrances land and the essentials load resolve.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 160));
    await tester.pump(const Duration(milliseconds: 320));
    await tester.pump(const Duration(milliseconds: 320));

    expect(find.byType(LullShell), findsOneWidget);
    expect(find.byType(TodayScreen), findsOneWidget);
  });
}
