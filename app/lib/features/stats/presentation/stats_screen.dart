import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lull/core/theme/theme.dart';
import 'package:lull/ui/animations/lull_entrance.dart';
import 'package:lull/ui/components/lull_scaffold.dart';

/// Stats tab, M0: a composed empty state — a quiet chart silhouette and a
/// gentle promise of the week to come.
class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spacing = context.spacing;
    final type = context.type;

    return LullScaffold(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(spacing.screenPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LullEntrance(
              index: 0,
              child: Text('your week', style: type.heading),
            ),
            SizedBox(height: spacing.xl),
            const LullEntrance(index: 1, child: _ChartSilhouette()),
            SizedBox(height: spacing.xl),
            LullEntrance(
              index: 2,
              child: Text(
                'your story starts with one session',
                textAlign: TextAlign.center,
                style: type.bodySoft,
              ),
            ),
            SizedBox(height: spacing.lg),
            const LullEntrance(index: 3, child: Center(child: _DayChip())),
          ],
        ),
      ),
    );
  }
}

/// A disabled-looking week of soft hairline bars — what the chart will be,
/// not a chart pretending to have data.
class _ChartSilhouette extends StatelessWidget {
  const _ChartSilhouette();

  static const double _height = 140;

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: spacing.xl,
        vertical: spacing.xl,
      ),
      decoration: BoxDecoration(
        color: context.colors.bg2,
        borderRadius: context.radii.brLg,
      ),
      child: RepaintBoundary(
        child: SizedBox(
          height: _height,
          width: double.infinity,
          child: CustomPaint(
            painter: _SilhouetteBarsPainter(color: context.colors.hairline),
          ),
        ),
      ),
    );
  }
}

class _SilhouetteBarsPainter extends CustomPainter {
  const _SilhouetteBarsPainter({required this.color});

  final Color color;

  // Seven days of placeholder heights, deliberately uneven so the
  // silhouette reads as "a week" rather than a pattern.
  static const List<double> _heights = [
    0.32,
    0.52,
    0.38,
    0.72,
    0.46,
    0.6,
    0.26,
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final count = _heights.length;

    // Equal bar and gap widths: n bars + (n - 1) gaps.
    final barWidth = size.width / (count * 2 - 1);
    final radius = Radius.circular(barWidth / 2);

    for (var i = 0; i < count; i++) {
      final barHeight = size.height * _heights[i];
      final rect = Rect.fromLTWH(
        i * barWidth * 2,
        size.height - barHeight,
        barWidth,
        barHeight,
      );
      canvas.drawRRect(RRect.fromRectAndRadius(rect, radius), paint);
    }
  }

  @override
  bool shouldRepaint(_SilhouetteBarsPainter oldDelegate) =>
      color != oldDelegate.color;
}

class _DayChip extends StatelessWidget {
  const _DayChip();

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: spacing.lg,
        vertical: spacing.sm,
      ),
      decoration: BoxDecoration(
        borderRadius: context.radii.brPill,
        border: Border.all(color: context.colors.hairline),
      ),
      child: Text('DAY 1 — GENTLY DOES IT', style: context.type.label),
    );
  }
}
