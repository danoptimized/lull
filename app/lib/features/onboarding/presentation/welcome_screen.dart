import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lull/core/theme/theme.dart';
import 'package:lull/features/onboarding/application/onboarding.dart';
import 'package:lull/ui/animations/lull_entrance.dart';
import 'package:lull/ui/components/lull_pill_button.dart';
import 'package:lull/ui/components/lull_scaffold.dart';

/// One calm first-run screen: what lull is, then a single way in. Shown once,
/// gated by [onboardingSeenProvider]; "begin" marks it seen and the router
/// moves on to Today.
class WelcomeScreen extends ConsumerWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spacing = context.spacing;
    final type = context.type;

    return LullScaffold(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: spacing.screenPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Spacer(),
            LullEntrance(index: 0, child: Text('lull', style: type.display)),
            SizedBox(height: spacing.md),
            LullEntrance(
              index: 1,
              child: Text(
                'a quiet place for your three things.',
                style: type.bodySoft,
              ),
            ),
            SizedBox(height: spacing.xxl),
            const LullEntrance(
              index: 2,
              child: _Point(text: 'choose three essentials each day'),
            ),
            SizedBox(height: spacing.lg),
            const LullEntrance(
              index: 3,
              child: _Point(text: 'focus in calm 25-minute sessions'),
            ),
            SizedBox(height: spacing.lg),
            const LullEntrance(
              index: 4,
              child: _Point(text: 'earn rewards for showing up'),
            ),
            const Spacer(),
            LullEntrance(
              index: 5,
              child: SizedBox(
                width: double.infinity,
                child: LullPillButton(
                  label: 'begin',
                  // Marking onboarding seen rebuilds the router, which redirects
                  // /welcome → /today on its own (same mechanism as sign-in).
                  // Navigating here too would race that rebuild and blank the page.
                  onPressed: () =>
                      ref.read(onboardingSeenProvider.notifier).markSeen(),
                ),
              ),
            ),
            SizedBox(height: spacing.screenPadding),
          ],
        ),
      ),
    );
  }
}

class _Point extends StatelessWidget {
  const _Point({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final spacing = context.spacing;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(top: spacing.sm),
          child: Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: colors.aurora,
            ),
          ),
        ),
        SizedBox(width: spacing.md),
        Expanded(child: Text(text, style: context.type.body)),
      ],
    );
  }
}
