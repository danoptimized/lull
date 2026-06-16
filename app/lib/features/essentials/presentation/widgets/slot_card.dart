import 'package:flutter/material.dart';

import 'package:lull/core/theme/theme.dart';
import 'package:lull/features/essentials/domain/essential.dart';

/// One of the three essential slots on the Today screen.
///
/// A `null` [essential] renders the ghost state inviting the user to fill
/// the slot. [slot] is 1-based and only feeds the ghost copy.
class SlotCard extends StatelessWidget {
  const SlotCard({super.key, required this.essential, required this.slot});

  final Essential? essential;
  final int slot;

  // Keeps three stacked cards feeling substantial even with short titles.
  static const double _minHeight = 88;

  @override
  Widget build(BuildContext context) {
    final essential = this.essential;
    if (essential == null) {
      return _GhostCard(slot: slot, minHeight: _minHeight);
    }

    final colors = context.colors;
    final spacing = context.spacing;
    final type = context.type;
    final done = essential.complete;
    final light = Theme.of(context).brightness == Brightness.light;

    final background = done
        ? Color.alphaBlend(colors.success.withValues(alpha: 0.05), colors.bg2)
        : colors.bg2;

    return Container(
      constraints: const BoxConstraints(minHeight: _minHeight),
      padding: EdgeInsets.symmetric(
        horizontal: spacing.xl,
        vertical: spacing.lg,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: context.radii.brLg,
        // Dark relies on bg2-vs-bg1 tone steps; light gets the soft
        // glow-shadow lift (DESIGN.md: ≤12% opacity, 24–40 blur).
        boxShadow: light
            ? <BoxShadow>[
                BoxShadow(
                  color: colors.textPrimary.withValues(alpha: 0.05),
                  blurRadius: 24,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  essential.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: done
                      ? type.body.copyWith(color: colors.textSecondary)
                      : type.body,
                ),
              ),
              if (done) ...[
                SizedBox(width: spacing.md),
                // A bare check, not a filled disc: finished work recedes,
                // the remaining work leads.
                Icon(
                  Icons.check_rounded,
                  size: 16,
                  color: colors.success,
                  semanticLabel: 'completed',
                ),
              ],
            ],
          ),
          SizedBox(height: spacing.md),
          Opacity(
            // Done rows settle: their dots dim along with the title.
            opacity: done ? 0.6 : 1,
            child: _TargetDots(
              completed: essential.completedPomodoros,
              target: essential.targetPomodoros,
            ),
          ),
        ],
      ),
    );
  }
}

/// ●●○-style pomodoro progress: filled dots wear the aurora gradient,
/// remaining ones are hairline outlines.
class _TargetDots extends StatelessWidget {
  const _TargetDots({required this.completed, required this.target});

  final int completed;
  final int target;

  static const double _dotSize = 8;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final spacing = context.spacing;

    return Semantics(
      label: '$completed of $target pomodoros',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < target; i++) ...[
            if (i > 0) SizedBox(width: spacing.sm),
            Container(
              width: _dotSize,
              height: _dotSize,
              decoration: i < completed
                  ? BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: colors.aurora,
                    )
                  : BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: colors.hairline),
                    ),
            ),
          ],
        ],
      ),
    );
  }
}

class _GhostCard extends StatelessWidget {
  const _GhostCard({required this.slot, required this.minHeight});

  final int slot;
  final double minHeight;

  String get _ordinal => switch (slot) {
    1 => 'first',
    2 => 'second',
    3 => 'third',
    _ => 'next',
  };

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final spacing = context.spacing;

    return CustomPaint(
      painter: _DashedRRectPainter(
        color: colors.hairline,
        radius: context.radii.lg,
      ),
      child: Container(
        constraints: BoxConstraints(minHeight: minHeight),
        padding: EdgeInsets.symmetric(
          horizontal: spacing.xl,
          vertical: spacing.lg,
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add_rounded, size: 18, color: colors.textFaint),
            SizedBox(width: spacing.sm),
            Text('add your $_ordinal essential', style: context.type.bodySoft),
          ],
        ),
      ),
    );
  }
}

/// Dashed rounded-rect border for the ghost slot — Flutter has no dashed
/// [BorderSide], so the outline is dashed by walking the path metrics.
class _DashedRRectPainter extends CustomPainter {
  const _DashedRRectPainter({required this.color, required this.radius});

  final Color color;
  final double radius;

  static const double _dash = 5;
  static const double _gap = 5;
  static const double _stroke = 1;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = _stroke
      ..strokeCap = StrokeCap.round;

    // Inset by half the stroke so the hairline isn't clipped at the edges.
    final rect = (Offset.zero & size).deflate(_stroke / 2);
    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(rect, Radius.circular(radius)));

    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        canvas.drawPath(metric.extractPath(distance, distance + _dash), paint);
        distance += _dash + _gap;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedRRectPainter oldDelegate) =>
      color != oldDelegate.color || radius != oldDelegate.radius;
}
