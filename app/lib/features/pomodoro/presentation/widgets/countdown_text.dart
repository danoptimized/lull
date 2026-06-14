import 'package:flutter/material.dart';
import 'package:lull/core/theme/theme.dart';

/// The focus clock, `mm:ss`, in the `display` style.
///
/// Each digit sits in a fixed-width box (0.62 × font size) and the colon in
/// a narrower centered one, so the clock never jitters as digits change —
/// belt and suspenders on top of tabular figures (DESIGN.md).
class CountdownText extends StatelessWidget {
  const CountdownText({super.key, required this.seconds});

  final int seconds;

  static const double _digitWidthFactor = 0.62;

  @override
  Widget build(BuildContext context) {
    final style = context.type.display.copyWith(
      color: context.colors.textPrimary,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    // Slot widths follow the *scaled* glyph size, or large text scales would
    // overflow the fixed boxes and clip.
    final scaledFontSize = MediaQuery.textScalerOf(
      context,
    ).scale(style.fontSize ?? 88);
    final digitWidth = scaledFontSize * _digitWidthFactor;
    final colonWidth = digitWidth * 0.5;

    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');

    return Semantics(
      label: '$minutes:$secs',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final char in '$minutes:$secs'.split(''))
            SizedBox(
              width: char == ':' ? colonWidth : digitWidth,
              child: Text(
                char,
                textAlign: TextAlign.center,
                maxLines: 1,
                style: style,
              ),
            ),
        ],
      ),
    );
  }
}
