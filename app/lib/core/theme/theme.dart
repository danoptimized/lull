import 'package:flutter/material.dart';

import 'lull_colors.dart';
import 'lull_motion_tokens.dart';
import 'lull_radii.dart';
import 'lull_spacing.dart';
import 'lull_typography.dart';

export 'lull_colors.dart';
export 'lull_motion_tokens.dart';
export 'lull_radii.dart';
export 'lull_spacing.dart';
export 'lull_typography.dart';

/// Builds the Lull [ThemeData] for [brightness].
///
/// Dark is "pre-dawn" (the hero), light is "morning paper". All five token
/// extensions are registered; widgets read them via `context.colors` etc.
/// and must never reach for `ColorScheme` directly.
ThemeData buildLullTheme(Brightness brightness) {
  final colors = brightness == Brightness.dark
      ? LullColors.dark
      : LullColors.light;
  final type = LullTypography.fromColors(colors);
  const spacing = LullSpacing();
  const radii = LullRadii();
  const motion = LullMotionTokens();

  return ThemeData(
    useMaterial3: true,
    colorScheme: _schemeFor(brightness, colors),
    scaffoldBackgroundColor: colors.bg1,
    canvasColor: colors.bg1,
    cardColor: colors.bg2,
    fontFamily: LullTypography.fontFamily,
    textTheme: _textThemeFrom(type),
    // Quiet feedback: a barely-there teal wash instead of Material's
    // default splash energy.
    splashFactory: InkRipple.splashFactory,
    splashColor: colors.accentTeal.withValues(alpha: 0.08),
    highlightColor: colors.accentTeal.withValues(alpha: 0.06),
    hoverColor: colors.accentTeal.withValues(alpha: 0.04),
    focusColor: colors.accentTeal.withValues(alpha: 0.10),
    dividerColor: colors.hairline,
    dividerTheme: DividerThemeData(
      color: colors.hairline,
      thickness: 1,
      space: 1,
    ),
    iconTheme: IconThemeData(color: colors.textSecondary),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      centerTitle: false,
      foregroundColor: colors.textPrimary,
      titleTextStyle: type.heading,
      iconTheme: IconThemeData(color: colors.textSecondary),
    ),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: colors.accentTeal,
      selectionColor: colors.accentTeal.withValues(alpha: 0.25),
      selectionHandleColor: colors.accentTeal,
    ),
    extensions: <ThemeExtension<dynamic>>[colors, spacing, radii, motion, type],
  );
}

/// Manual scheme for palette fidelity — seeding would drift the hues.
ColorScheme _schemeFor(Brightness brightness, LullColors c) {
  final isDark = brightness == Brightness.dark;
  // Accents are light in dark mode and deep in light mode, so the matching
  // "on" color is the deepest backdrop or the raised white respectively.
  final onAccent = isDark ? c.bg0 : c.bg2;
  return ColorScheme(
    brightness: brightness,
    primary: c.accentTeal,
    onPrimary: onAccent,
    primaryContainer: c.bg2,
    onPrimaryContainer: c.accentTeal,
    secondary: c.accentLavender,
    onSecondary: onAccent,
    secondaryContainer: c.bg2,
    onSecondaryContainer: c.accentLavender,
    tertiary: c.breakWarm,
    onTertiary: onAccent,
    error: c.danger,
    onError: onAccent,
    surface: c.bg1,
    onSurface: c.textPrimary,
    onSurfaceVariant: c.textSecondary,
    outline: c.hairline,
    outlineVariant: c.hairline,
    surfaceContainerLowest: c.bg0,
    surfaceContainerLow: c.bg1,
    surfaceContainer: c.bg2,
    surfaceContainerHigh: c.bg2,
    surfaceContainerHighest: c.bg2,
    inverseSurface: c.textPrimary,
    onInverseSurface: c.bg0,
    inversePrimary: isDark
        ? LullColors.light.accentTeal
        : LullColors.dark.accentTeal,
    // No M3 elevation tint — surfaces step via bg0/bg1/bg2 tone instead.
    surfaceTint: Colors.transparent,
    shadow: Colors.black,
    scrim: Colors.black,
  );
}

TextTheme _textThemeFrom(LullTypography type) {
  return TextTheme(
    displayLarge: type.display,
    displayMedium: type.title,
    headlineMedium: type.title,
    headlineSmall: type.heading,
    titleLarge: type.title,
    titleMedium: type.heading,
    titleSmall: type.body,
    bodyLarge: type.body,
    bodyMedium: type.body,
    bodySmall: type.caption,
    labelLarge: type.body,
    labelMedium: type.caption,
    labelSmall: type.label,
  );
}

/// Aggregate token handle, so `context.lull.colors` also reads naturally.
@immutable
class Lull {
  const Lull._(this.colors, this.spacing, this.radii, this.motion, this.type);

  final LullColors colors;
  final LullSpacing spacing;
  final LullRadii radii;
  final LullMotionTokens motion;
  final LullTypography type;
}

/// Token access for widgets: `context.colors.accentTeal`,
/// `context.spacing.xl`, `context.motion.calm`, `context.type.label`.
extension LullTheme on BuildContext {
  LullColors get colors => Theme.of(this).extension<LullColors>()!;
  LullSpacing get spacing => Theme.of(this).extension<LullSpacing>()!;
  LullRadii get radii => Theme.of(this).extension<LullRadii>()!;
  LullMotionTokens get motion => Theme.of(this).extension<LullMotionTokens>()!;
  LullTypography get type => Theme.of(this).extension<LullTypography>()!;

  Lull get lull => Lull._(colors, spacing, radii, motion, type);
}
