import 'package:flutter/material.dart';

import 'lull_colors.dart';

/// Lull type ramp — Manrope throughout, see DESIGN.md "Typography".
///
/// Styles carry their token color (e.g. [bodySoft] is textSecondary), so a
/// bare `Text(style: context.type.caption)` is already on-palette.
/// [label] carries the +0.8 tracking; callers apply UPPERCASE themselves.
@immutable
class LullTypography extends ThemeExtension<LullTypography> {
  const LullTypography({
    required this.display,
    required this.title,
    required this.heading,
    required this.body,
    required this.bodySoft,
    required this.caption,
    required this.label,
  });

  /// Builds the ramp tinted for the given palette.
  factory LullTypography.fromColors(LullColors colors) {
    return LullTypography(
      // Tabular figures keep the countdown from jittering; callers add
      // fixed-width digit slots on top (belt and suspenders).
      display: TextStyle(
        fontFamily: fontFamily,
        fontSize: 88,
        fontWeight: FontWeight.w300,
        height: 1.05,
        fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
        color: colors.textPrimary,
      ),
      title: TextStyle(
        fontFamily: fontFamily,
        fontSize: 28,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        height: 1.2,
        color: colors.textPrimary,
      ),
      heading: TextStyle(
        fontFamily: fontFamily,
        fontSize: 20,
        fontWeight: FontWeight.w600,
        height: 1.3,
        color: colors.textPrimary,
      ),
      body: TextStyle(
        fontFamily: fontFamily,
        fontSize: 15,
        fontWeight: FontWeight.w500,
        height: 1.5,
        color: colors.textPrimary,
      ),
      bodySoft: TextStyle(
        fontFamily: fontFamily,
        fontSize: 15,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: colors.textSecondary,
      ),
      caption: TextStyle(
        fontFamily: fontFamily,
        fontSize: 13,
        fontWeight: FontWeight.w500,
        height: 1.4,
        color: colors.textSecondary,
      ),
      label: TextStyle(
        fontFamily: fontFamily,
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
        height: 1.2,
        color: colors.textFaint,
      ),
    );
  }

  /// Bundled variable font, weights 300–800.
  static const String fontFamily = 'Manrope';

  final TextStyle display;
  final TextStyle title;
  final TextStyle heading;
  final TextStyle body;
  final TextStyle bodySoft;
  final TextStyle caption;
  final TextStyle label;

  @override
  LullTypography copyWith({
    TextStyle? display,
    TextStyle? title,
    TextStyle? heading,
    TextStyle? body,
    TextStyle? bodySoft,
    TextStyle? caption,
    TextStyle? label,
  }) {
    return LullTypography(
      display: display ?? this.display,
      title: title ?? this.title,
      heading: heading ?? this.heading,
      body: body ?? this.body,
      bodySoft: bodySoft ?? this.bodySoft,
      caption: caption ?? this.caption,
      label: label ?? this.label,
    );
  }

  @override
  LullTypography lerp(ThemeExtension<LullTypography>? other, double t) {
    if (other is! LullTypography) return this;
    return LullTypography(
      display: TextStyle.lerp(display, other.display, t)!,
      title: TextStyle.lerp(title, other.title, t)!,
      heading: TextStyle.lerp(heading, other.heading, t)!,
      body: TextStyle.lerp(body, other.body, t)!,
      bodySoft: TextStyle.lerp(bodySoft, other.bodySoft, t)!,
      caption: TextStyle.lerp(caption, other.caption, t)!,
      label: TextStyle.lerp(label, other.label, t)!,
    );
  }
}
