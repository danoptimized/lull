import 'package:flutter/widgets.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lull/core/motion/motion.dart';

/// The canonical entrance for anything that appears on screen: a calm
/// fade-in while rising 12px, staggered 40ms per [index].
///
/// Wrap each item of a list (or each block of a screen) and pass its
/// position as [index]; item 0 starts immediately, each subsequent item
/// 40ms later.
///
/// Reduced motion (OS setting or the in-app preference): the rise is
/// dropped entirely and the child appears with a plain 120ms fade.
class LullEntrance extends ConsumerWidget {
  const LullEntrance({super.key, required this.index, required this.child});

  /// Zero-based position in the entrance sequence; drives the stagger delay.
  final int index;

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (Motion.reduce(context, ref)) {
      return Animate(
        effects: Motion.fade(context, duration: Motion.reducedFade),
        child: child,
      );
    }
    return Animate(
      effects: Motion.enter(context, delay: Motion.staggerFor(index)),
      child: child,
    );
  }
}
