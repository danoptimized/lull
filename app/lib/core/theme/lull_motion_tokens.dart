import 'package:flutter/material.dart';

/// Lull motion tokens — see DESIGN.md "Motion tokens".
///
/// Rules: entrances fade+rise 12px with [calm], staggered 40ms per item.
/// Never bounce, never overshoot. Under reduced motion, looping/decorative
/// motion stops and entrances become simple 120ms fades.
@immutable
class LullMotionTokens extends ThemeExtension<LullMotionTokens> {
  const LullMotionTokens({
    this.instant = const Duration(milliseconds: 80),
    this.quick = const Duration(milliseconds: 160),
    this.calm = const Duration(milliseconds: 320),
    this.slow = const Duration(milliseconds: 640),
    this.breathing = const Duration(milliseconds: 6000),
    this.gentleOut = Curves.easeOutCubic,
    this.gentleInOut = Curves.easeInOutCubic,
    this.breathe = Curves.easeInOutSine,
  });

  final Duration instant;
  final Duration quick;
  final Duration calm;
  final Duration slow;
  final Duration breathing;

  final Curve gentleOut;
  final Curve gentleInOut;
  final Curve breathe;

  @override
  LullMotionTokens copyWith({
    Duration? instant,
    Duration? quick,
    Duration? calm,
    Duration? slow,
    Duration? breathing,
    Curve? gentleOut,
    Curve? gentleInOut,
    Curve? breathe,
  }) {
    return LullMotionTokens(
      instant: instant ?? this.instant,
      quick: quick ?? this.quick,
      calm: calm ?? this.calm,
      slow: slow ?? this.slow,
      breathing: breathing ?? this.breathing,
      gentleOut: gentleOut ?? this.gentleOut,
      gentleInOut: gentleInOut ?? this.gentleInOut,
      breathe: breathe ?? this.breathe,
    );
  }

  @override
  LullMotionTokens lerp(ThemeExtension<LullMotionTokens>? other, double t) {
    if (other is! LullMotionTokens) return this;
    // Curves cannot be interpolated; snap at the midpoint.
    final LullMotionTokens curveSource = t < 0.5 ? this : other;
    return LullMotionTokens(
      instant: _lerpDuration(instant, other.instant, t),
      quick: _lerpDuration(quick, other.quick, t),
      calm: _lerpDuration(calm, other.calm, t),
      slow: _lerpDuration(slow, other.slow, t),
      breathing: _lerpDuration(breathing, other.breathing, t),
      gentleOut: curveSource.gentleOut,
      gentleInOut: curveSource.gentleInOut,
      breathe: curveSource.breathe,
    );
  }

  static Duration _lerpDuration(Duration a, Duration b, double t) {
    return Duration(
      microseconds:
          (a.inMicroseconds + (b.inMicroseconds - a.inMicroseconds) * t)
              .round(),
    );
  }
}
