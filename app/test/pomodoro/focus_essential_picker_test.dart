import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lull/core/theme/theme.dart';
import 'package:lull/features/essentials/application/essentials_controller.dart';
import 'package:lull/features/essentials/domain/essential.dart';
import 'package:lull/features/pomodoro/presentation/widgets/focus_essential_picker.dart';

void main() {
  const writeDraft = Essential(
    id: 'e1',
    slot: 1,
    title: 'write the draft',
    targetPomodoros: 3,
    completedPomodoros: 1,
  );
  final reviewPrs = Essential(
    id: 'e2',
    slot: 2,
    title: 'review the PRs',
    targetPomodoros: 2,
    completedPomodoros: 2,
    completedAt: DateTime.utc(2026),
  );

  // Pumps a trivial screen with one button that opens the picker and forwards
  // its result. `slots` is the fixed essential layout; `suggested` is the
  // next-unfinished the picker should highlight.
  Future<void> pump(
    WidgetTester tester, {
    required List<Essential?> slots,
    required Essential? suggested,
    required void Function(FocusChoice?) onResult,
  }) {
    return tester.pumpWidget(
      ProviderScope(
        overrides: [
          essentialSlotsProvider.overrideWithValue(slots),
          nextEssentialProvider.overrideWithValue(suggested),
        ],
        child: MaterialApp(
          theme: buildLullTheme(Brightness.dark),
          home: Scaffold(
            body: Builder(
              builder: (context) => Center(
                child: ElevatedButton(
                  onPressed: () async =>
                      onResult(await showFocusEssentialPicker(context)),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('lists filled essentials and returns the tapped one', (
    tester,
  ) async {
    FocusChoice? result;
    var returned = false;
    await pump(
      tester,
      slots: [writeDraft, reviewPrs, null],
      suggested: writeDraft,
      onResult: (r) {
        result = r;
        returned = true;
      },
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    // The empty third slot is skipped; both filled essentials are listed.
    expect(find.text('what are you focusing on?'), findsOneWidget);
    expect(find.text('write the draft'), findsOneWidget);
    expect(find.text('review the PRs'), findsOneWidget);
    // The suggested (next unfinished) one is tagged; the done one shows 'done'.
    expect(find.text('suggested'), findsOneWidget);
    expect(find.text('1 of 3 pomodoros'), findsOneWidget);
    expect(find.text('done'), findsOneWidget);

    await tester.tap(find.text('write the draft'));
    await tester.pumpAndSettle();

    expect(returned, isTrue);
    expect(result?.essential?.id, 'e1');
  });

  testWidgets('"focus without a task" returns a null-essential choice', (
    tester,
  ) async {
    FocusChoice? result;
    var returned = false;
    await pump(
      tester,
      slots: [writeDraft, null, null],
      suggested: writeDraft,
      onResult: (r) {
        result = r;
        returned = true;
      },
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('focus without a task'));
    await tester.pumpAndSettle();

    expect(returned, isTrue);
    expect(result, isNotNull);
    expect(result!.essential, isNull);
  });

  testWidgets('dismissing the sheet returns null', (tester) async {
    FocusChoice? result;
    var returned = false;
    await pump(
      tester,
      slots: [writeDraft, null, null],
      suggested: writeDraft,
      onResult: (r) {
        result = r;
        returned = true;
      },
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    // Tap the scrim above the sheet to dismiss without choosing.
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    expect(returned, isTrue);
    expect(result, isNull);
  });
}
