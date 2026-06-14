import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

/// Lull spacing scale (4-base) — see DESIGN.md "Spacing / radii / elevation".
@immutable
class LullSpacing extends ThemeExtension<LullSpacing> {
  const LullSpacing({
    this.xs = 4,
    this.sm = 8,
    this.md = 12,
    this.lg = 16,
    this.xl = 24,
    this.xxl = 32,
    this.xxxl = 48,
    this.huge = 64,
    this.screenPadding = 24,
  });

  final double xs;
  final double sm;
  final double md;
  final double lg;
  final double xl;
  final double xxl;
  final double xxxl;
  final double huge;
  final double screenPadding;

  @override
  LullSpacing copyWith({
    double? xs,
    double? sm,
    double? md,
    double? lg,
    double? xl,
    double? xxl,
    double? xxxl,
    double? huge,
    double? screenPadding,
  }) {
    return LullSpacing(
      xs: xs ?? this.xs,
      sm: sm ?? this.sm,
      md: md ?? this.md,
      lg: lg ?? this.lg,
      xl: xl ?? this.xl,
      xxl: xxl ?? this.xxl,
      xxxl: xxxl ?? this.xxxl,
      huge: huge ?? this.huge,
      screenPadding: screenPadding ?? this.screenPadding,
    );
  }

  @override
  LullSpacing lerp(ThemeExtension<LullSpacing>? other, double t) {
    if (other is! LullSpacing) return this;
    return LullSpacing(
      xs: lerpDouble(xs, other.xs, t)!,
      sm: lerpDouble(sm, other.sm, t)!,
      md: lerpDouble(md, other.md, t)!,
      lg: lerpDouble(lg, other.lg, t)!,
      xl: lerpDouble(xl, other.xl, t)!,
      xxl: lerpDouble(xxl, other.xxl, t)!,
      xxxl: lerpDouble(xxxl, other.xxxl, t)!,
      huge: lerpDouble(huge, other.huge, t)!,
      screenPadding: lerpDouble(screenPadding, other.screenPadding, t)!,
    );
  }
}
