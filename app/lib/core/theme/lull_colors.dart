import 'package:flutter/material.dart';

/// Lull color tokens — see DESIGN.md "Color tokens".
///
/// Two fixed palettes: [dark] ("pre-dawn", the hero) and [light]
/// ("morning paper"). Widgets must read these via `context.colors`,
/// never construct colors themselves.
@immutable
class LullColors extends ThemeExtension<LullColors> {
  const LullColors({
    required this.bg0,
    required this.bg1,
    required this.bg2,
    required this.hairline,
    required this.textPrimary,
    required this.textSecondary,
    required this.textFaint,
    required this.accentTeal,
    required this.accentLavender,
    required this.breakWarm,
    required this.success,
    required this.danger,
    required this.auroraStart,
    required this.auroraEnd,
  });

  /// Dark — "pre-dawn". Deep blue-charcoal, never pure black.
  static const LullColors dark = LullColors(
    bg0: Color(0xFF0A0E13),
    bg1: Color(0xFF10161D),
    bg2: Color(0xFF161E27),
    hairline: Color(0xFF232E3A),
    textPrimary: Color(0xFFE8EDF2),
    textSecondary: Color(0xFF9AA7B4),
    // 4.5:1+ on bg0/bg1/bg2 (it colors 11px labels), still clearly
    // subordinate to textSecondary.
    textFaint: Color(0xFF7A8794),
    accentTeal: Color(0xFF74C7B8),
    accentLavender: Color(0xFF8F86E8),
    breakWarm: Color(0xFFE8A87C),
    success: Color(0xFFE8C476),
    danger: Color(0xFFD98A8A),
    auroraStart: Color(0xFF74C7B8),
    auroraEnd: Color(0xFF8F86E8),
  );

  /// Light — "morning paper". Warm paper white, ink text.
  static const LullColors light = LullColors(
    bg0: Color(0xFFF2F1EC),
    bg1: Color(0xFFF7F6F2),
    bg2: Color(0xFFFFFFFF),
    hairline: Color(0xFFE3E1D8),
    textPrimary: Color(0xFF1F2933),
    textSecondary: Color(0xFF5A6672),
    // Same desaturated sage-gray family, but 4.5:1+ on every light surface
    // (it colors 11px labels and quiet icons).
    textFaint: Color(0xFF656E6B),
    // These accents double as small text in light mode (links, ledger amounts,
    // the PAUSED label, sign-out, errors, the done check), so they're tuned to
    // clear WCAG 4.5:1 on bg0/bg1/bg2 — deeper than their vivid dark-mode kin.
    accentTeal: Color(0xFF236B61),
    accentLavender: Color(0xFF6457C8),
    breakWarm: Color(0xFF9E5527),
    success: Color(0xFF9E7320),
    danger: Color(0xFFA84848),
    // Deeper than accentTeal so near-white CTA text clears 4.5:1 across the
    // whole gradient sweep.
    auroraStart: Color(0xFF257368),
    auroraEnd: Color(0xFF6457C8),
  );

  final Color bg0;
  final Color bg1;
  final Color bg2;
  final Color hairline;
  final Color textPrimary;
  final Color textSecondary;
  final Color textFaint;
  final Color accentTeal;
  final Color accentLavender;
  final Color breakWarm;
  final Color success;
  final Color danger;
  final Color auroraStart;
  final Color auroraEnd;

  /// The signature teal → lavender sweep at 135° (top-left → bottom-right).
  /// Used by the progress ring, focus glow, and the primary CTA fill.
  LinearGradient get aurora => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[auroraStart, auroraEnd],
  );

  @override
  LullColors copyWith({
    Color? bg0,
    Color? bg1,
    Color? bg2,
    Color? hairline,
    Color? textPrimary,
    Color? textSecondary,
    Color? textFaint,
    Color? accentTeal,
    Color? accentLavender,
    Color? breakWarm,
    Color? success,
    Color? danger,
    Color? auroraStart,
    Color? auroraEnd,
  }) {
    return LullColors(
      bg0: bg0 ?? this.bg0,
      bg1: bg1 ?? this.bg1,
      bg2: bg2 ?? this.bg2,
      hairline: hairline ?? this.hairline,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textFaint: textFaint ?? this.textFaint,
      accentTeal: accentTeal ?? this.accentTeal,
      accentLavender: accentLavender ?? this.accentLavender,
      breakWarm: breakWarm ?? this.breakWarm,
      success: success ?? this.success,
      danger: danger ?? this.danger,
      auroraStart: auroraStart ?? this.auroraStart,
      auroraEnd: auroraEnd ?? this.auroraEnd,
    );
  }

  @override
  LullColors lerp(ThemeExtension<LullColors>? other, double t) {
    if (other is! LullColors) return this;
    return LullColors(
      bg0: Color.lerp(bg0, other.bg0, t)!,
      bg1: Color.lerp(bg1, other.bg1, t)!,
      bg2: Color.lerp(bg2, other.bg2, t)!,
      hairline: Color.lerp(hairline, other.hairline, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textFaint: Color.lerp(textFaint, other.textFaint, t)!,
      accentTeal: Color.lerp(accentTeal, other.accentTeal, t)!,
      accentLavender: Color.lerp(accentLavender, other.accentLavender, t)!,
      breakWarm: Color.lerp(breakWarm, other.breakWarm, t)!,
      success: Color.lerp(success, other.success, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      auroraStart: Color.lerp(auroraStart, other.auroraStart, t)!,
      auroraEnd: Color.lerp(auroraEnd, other.auroraEnd, t)!,
    );
  }
}
