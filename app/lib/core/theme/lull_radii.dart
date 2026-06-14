import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

/// Lull corner radii — see DESIGN.md "Spacing / radii / elevation".
/// Cards use [lg]; buttons and chips use [pill].
@immutable
class LullRadii extends ThemeExtension<LullRadii> {
  const LullRadii({this.sm = 10, this.md = 14, this.lg = 20, this.pill = 999});

  final double sm;
  final double md;
  final double lg;
  final double pill;

  BorderRadius get brSm => BorderRadius.circular(sm);
  BorderRadius get brMd => BorderRadius.circular(md);
  BorderRadius get brLg => BorderRadius.circular(lg);
  BorderRadius get brPill => BorderRadius.circular(pill);

  @override
  LullRadii copyWith({double? sm, double? md, double? lg, double? pill}) {
    return LullRadii(
      sm: sm ?? this.sm,
      md: md ?? this.md,
      lg: lg ?? this.lg,
      pill: pill ?? this.pill,
    );
  }

  @override
  LullRadii lerp(ThemeExtension<LullRadii>? other, double t) {
    if (other is! LullRadii) return this;
    return LullRadii(
      sm: lerpDouble(sm, other.sm, t)!,
      md: lerpDouble(md, other.md, t)!,
      lg: lerpDouble(lg, other.lg, t)!,
      pill: lerpDouble(pill, other.pill, t)!,
    );
  }
}
