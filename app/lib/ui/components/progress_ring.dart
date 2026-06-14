import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lull/core/motion/motion.dart';
import 'package:lull/core/theme/theme.dart';

/// Aurora-gradient circular progress ring: faint hairline track, round caps,
/// optional soft glow at the arc tip. Progress changes animate implicitly
/// (snapping under reduced motion).
class ProgressRing extends ConsumerWidget {
  const ProgressRing({
    super.key,
    required this.progress,
    this.size = 56,
    this.strokeWidth = 4,
    this.glowTip = false,
    this.semanticLabel,
  });

  /// Completed fraction, 0.0–1.0 (clamped).
  final double progress;

  /// Outer diameter in logical pixels.
  final double size;

  /// Stroke thickness of both track and arc.
  final double strokeWidth;

  /// When true, a soft radial glow marks the leading tip of the arc
  /// (the focus screen's "progress tip" treatment).
  final bool glowTip;

  /// What this ring measures, for assistive tech (e.g. "day progress").
  final String? semanticLabel;

  /// Tiny arc painted at 12 o'clock when a [glowTip] ring sits at zero, so
  /// the dial carries the aurora before the session starts instead of being
  /// a bare gray circle.
  static const double _restingSeed = 0.012;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final motion = context.motion;
    final target = progress.clamp(0.0, 1.0);
    final display = (glowTip && target <= 0) ? _restingSeed : target;
    return Semantics(
      label: semanticLabel ?? 'progress',
      value: '${(target * 100).round()} percent',
      child: RepaintBoundary(
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0, end: display),
          duration: Motion.functional(context, ref, motion.calm),
          curve: motion.gentleOut,
          builder: (context, value, _) => SizedBox.square(
            dimension: size,
            child: CustomPaint(
              painter: _RingPainter(
                progress: value,
                strokeWidth: strokeWidth,
                trackColor: colors.hairline.withValues(alpha: 0.9),
                auroraStart: colors.auroraStart,
                auroraEnd: colors.auroraEnd,
                glowTip: glowTip,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({
    required this.progress,
    required this.strokeWidth,
    required this.trackColor,
    required this.auroraStart,
    required this.auroraEnd,
    required this.glowTip,
  });

  final double progress;
  final double strokeWidth;
  final Color trackColor;
  final Color auroraStart;
  final Color auroraEnd;
  final bool glowTip;

  static const double _topAngle = -math.pi / 2;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = (size.shortestSide - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..color = trackColor,
    );

    if (progress <= 0) {
      return;
    }

    final sweep = progress * 2 * math.pi;

    // Back-rotate the gradient by the cap's angular footprint so the round
    // start cap samples the start color instead of the wrapped end color.
    final capAngle = (strokeWidth / 2) / radius;
    final arcPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        colors: <Color>[auroraStart, auroraEnd],
        transform: GradientRotation(_topAngle - capAngle),
      ).createShader(rect);
    canvas.drawArc(rect, _topAngle, sweep, false, arcPaint);

    if (glowTip) {
      final tipAngle = _topAngle + sweep;
      final tip =
          center + Offset(math.cos(tipAngle), math.sin(tipAngle)) * radius;
      // Outer blur leaves the cap itself crisp and paints only the halo.
      canvas.drawCircle(
        tip,
        strokeWidth,
        Paint()
          ..color = Color.lerp(
            auroraStart,
            auroraEnd,
            progress,
          )!.withValues(alpha: 0.55)
          ..maskFilter = MaskFilter.blur(BlurStyle.outer, strokeWidth * 1.5),
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) =>
      progress != oldDelegate.progress ||
      strokeWidth != oldDelegate.strokeWidth ||
      trackColor != oldDelegate.trackColor ||
      auroraStart != oldDelegate.auroraStart ||
      auroraEnd != oldDelegate.auroraEnd ||
      glowTip != oldDelegate.glowTip;
}
