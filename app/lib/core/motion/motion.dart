import 'package:flutter/widgets.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lull/core/config/app_prefs.dart';
import 'package:lull/core/theme/theme.dart';

/// The single place M0 decides *whether* and *how* things move.
///
/// All effect lists pull their durations and curves from [LullMotionTokens]
/// via `context.motion`, so motion stays in lockstep with the design language:
/// entrances fade + rise, nothing ever bounces or overshoots.
abstract final class Motion {
  /// Per-item entrance stagger (DESIGN.md: 40ms per item).
  static const Duration stagger = Duration(milliseconds: 40);

  /// Duration of the fallback fade used when motion is reduced.
  ///
  /// Not a theme token on purpose: reduced motion deliberately ignores the
  /// expressive scale and uses one short, fixed fade everywhere.
  static const Duration reducedFade = Duration(milliseconds: 120);

  /// Whether motion should be reduced right now.
  ///
  /// True when either the OS accessibility setting
  /// ([MediaQuery.disableAnimationsOf]) or the in-app preference
  /// ([reducedMotionProvider]) asks for it. Subscribes via `ref.watch`, so
  /// call this from `build` only — the widget rebuilds when either changes.
  static bool reduce(BuildContext context, WidgetRef ref) {
    return MediaQuery.disableAnimationsOf(context) ||
        ref.watch(reducedMotionProvider);
  }

  /// Duration for *functional* state changes (progress sweeps, press
  /// feedback, nav fades, route transitions): the given token normally,
  /// [Duration.zero] under reduced motion — DESIGN.md says functional
  /// changes snap.
  static Duration functional(
    BuildContext context,
    WidgetRef ref,
    Duration duration,
  ) {
    return reduce(context, ref) ? Duration.zero : duration;
  }

  /// Convenience for staggered lists: the entrance delay for item [index].
  static Duration staggerFor(int index) => stagger * index;

  /// The canonical entrance: fade in while rising 12px, `calm` duration,
  /// `gentleOut` curve. Pass a [delay] (see [staggerFor]) to stagger items.
  static List<Effect<dynamic>> enter(
    BuildContext context, {
    Duration delay = Duration.zero,
  }) {
    final motion = context.motion;
    return <Effect<dynamic>>[
      FadeEffect(delay: delay, duration: motion.calm, curve: motion.gentleOut),
      MoveEffect(
        delay: delay,
        duration: motion.calm,
        curve: motion.gentleOut,
        begin: const Offset(0, 12),
        end: Offset.zero,
      ),
    ];
  }

  /// A plain fade-in, `quick` by default. Also the reduced-motion stand-in
  /// for [enter] when given [reducedFade] as the duration.
  static List<Effect<dynamic>> fade(
    BuildContext context, {
    Duration? duration,
    Duration delay = Duration.zero,
  }) {
    final motion = context.motion;
    return <Effect<dynamic>>[
      FadeEffect(
        delay: delay,
        duration: duration ?? motion.quick,
        curve: motion.gentleOut,
      ),
    ];
  }
}
