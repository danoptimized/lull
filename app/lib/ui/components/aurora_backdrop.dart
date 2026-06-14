import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:lull/core/theme/theme.dart';
import 'package:lull/ui/animations/breathing.dart';

/// The pre-dawn backdrop: a `bg0` base under two huge, barely-there radial
/// blooms that breathe out of phase so they drift. Shared chrome for the
/// focus and sign-in screens.
///
/// Pure pre-baked gradients — never a BackdropFilter (DESIGN.md).
class AuroraBackdrop extends StatelessWidget {
  const AuroraBackdrop({super.key});

  // DESIGN.md keeps the dark blooms at ~8–12% opacity.
  static const double _tealAlpha = 0.12;
  static const double _lavenderAlpha = 0.09;

  // In light mode the accents are lerped toward white before blending so a
  // bloom adds chroma without lowering the paper's luminance — a glow that
  // darkens reads as a stain, not an aurora.
  static const double _lightWhiteLerp = 0.55;
  static const double _lightAlpha = 0.30;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final light = Theme.of(context).brightness == Brightness.light;

    Color bloom(Color accent, double darkAlpha) => light
        ? Color.lerp(
            accent,
            Colors.white,
            _lightWhiteLerp,
          )!.withValues(alpha: _lightAlpha)
        : accent.withValues(alpha: darkAlpha);

    return RepaintBoundary(
      child: IgnorePointer(
        child: ColoredBox(
          color: colors.bg0,
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Size off the larger axis on wide screens so the blooms reach
              // toward the middle instead of pinning to the corners.
              final size = constraints.biggest;
              final diameter = math.max(
                size.shortestSide * 1.5,
                size.longestSide * 0.9,
              );
              return Stack(
                children: [
                  Positioned(
                    left: -diameter * 0.42,
                    top: -diameter * 0.38,
                    child: Breathing(
                      // Boundary inside the animated subtree: the bloom's
                      // picture is cached once and the per-frame breathing is
                      // applied as layer transforms instead of re-painting
                      // the ~1300px gradient every vsync.
                      child: RepaintBoundary(
                        child: _Bloom(
                          diameter: diameter,
                          color: bloom(colors.accentTeal, _tealAlpha),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    right: -diameter * 0.45,
                    bottom: -diameter * 0.40,
                    child: Breathing(
                      // De-phased via a start offset, not extra amplitude —
                      // DESIGN.md caps breathing at 1.00 ↔ 1.035.
                      phase: 0.4,
                      child: RepaintBoundary(
                        child: _Bloom(
                          diameter: diameter,
                          color: bloom(colors.accentLavender, _lavenderAlpha),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _Bloom extends StatelessWidget {
  const _Bloom({required this.diameter, required this.color});

  final double diameter;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        // The mid stop keeps the falloff soft and far-reaching; a two-stop
        // radial decays to nothing well before mid-screen.
        gradient: RadialGradient(
          colors: [
            color,
            color.withValues(alpha: color.a * 0.55),
            color.withValues(alpha: 0),
          ],
          stops: const [0.0, 0.45, 1.0],
        ),
      ),
    );
  }
}
