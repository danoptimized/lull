import 'package:flutter/widgets.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lull/core/motion/motion.dart';
import 'package:lull/core/theme/theme.dart';

/// Slow, looping "breathing" for decorative elements (aurora blooms, the
/// idle focus ring): a 6s ease-in-out-sine drift between scale 1.0 and
/// [scale], paired with a slight opacity rise from 0.92 to 1.0, reversing
/// forever. Purely ambient — never attach meaning to it.
///
/// Reduced motion (OS setting or the in-app preference): the loop stops and
/// the child is returned untouched, fully opaque at rest scale.
class Breathing extends ConsumerWidget {
  const Breathing({
    super.key,
    required this.child,
    this.scale = 1.035,
    this.phase = 0,
  });

  final Widget child;

  /// Peak scale at the top of the breath (DESIGN.md: 1.00 ↔ 1.035).
  final double scale;

  /// Starting point in the loop, 0.0–1.0 — offset neighbouring breathers
  /// so they drift out of phase instead of pulsing in lockstep.
  final double phase;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (Motion.reduce(context, ref)) {
      return child;
    }
    final motion = context.motion;
    return Animate(
      onPlay: (controller) {
        // `repeat` starts its simulation from the current value, so setting
        // it first acts as a phase offset.
        controller.value = phase.clamp(0.0, 1.0);
        controller.repeat(reverse: true);
      },
      effects: <Effect<dynamic>>[
        ScaleEffect(
          duration: motion.breathing,
          curve: motion.breathe,
          begin: const Offset(1, 1),
          end: Offset(scale, scale),
        ),
        FadeEffect(
          duration: motion.breathing,
          curve: motion.breathe,
          begin: 0.92,
          end: 1,
        ),
      ],
      child: child,
    );
  }
}
