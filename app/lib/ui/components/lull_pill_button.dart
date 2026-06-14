import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lull/core/motion/motion.dart';
import 'package:lull/core/theme/theme.dart';

/// Lull's pill button: primary is an aurora-gradient fill with a soft teal
/// glow; secondary is a quiet bg2 surface with a hairline border.
class LullPillButton extends ConsumerStatefulWidget {
  const LullPillButton({
    super.key,
    required this.label,
    this.onPressed,
    this.primary = true,
    this.icon,
  });

  final String label;

  /// Null renders the button disabled (dimmed, no glow, no ink).
  final VoidCallback? onPressed;

  final bool primary;

  /// Optional leading icon.
  final IconData? icon;

  // Min, not fixed: large text scales grow the pill instead of clipping it.
  static const double _minHeight = 56;
  static const double _iconSize = 20;

  // DESIGN.md elevation contract: glow-shadows stay ≤12% opacity.
  static const double _glowAlpha = 0.12;

  @override
  ConsumerState<LullPillButton> createState() => _LullPillButtonState();
}

class _LullPillButtonState extends ConsumerState<LullPillButton> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed != value) {
      setState(() => _pressed = value);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final spacing = context.spacing;
    final radii = context.radii;
    final motion = context.motion;
    final type = context.type;

    final enabled = widget.onPressed != null;
    final foreground = widget.primary ? colors.bg0 : colors.textPrimary;
    // Press/disable feedback snaps under reduced motion.
    final feedback = Motion.functional(context, ref, motion.quick);

    return Semantics(
      button: true,
      enabled: enabled,
      child: AnimatedScale(
        scale: _pressed ? 0.985 : 1.0,
        duration: feedback,
        curve: motion.gentleOut,
        child: AnimatedOpacity(
          opacity: enabled ? 1.0 : 0.55,
          duration: feedback,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: widget.primary ? colors.aurora : null,
              color: widget.primary ? null : colors.bg2,
              borderRadius: radii.brPill,
              border: widget.primary
                  ? null
                  : Border.all(color: colors.hairline),
              boxShadow: widget.primary && enabled
                  ? <BoxShadow>[
                      BoxShadow(
                        color: colors.accentTeal.withValues(
                          alpha: LullPillButton._glowAlpha,
                        ),
                        blurRadius: 32,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Material(
              type: MaterialType.transparency,
              child: InkWell(
                onTap: widget.onPressed,
                borderRadius: radii.brPill,
                onTapDown: enabled ? (_) => _setPressed(true) : null,
                onTapUp: enabled ? (_) => _setPressed(false) : null,
                onTapCancel: enabled ? () => _setPressed(false) : null,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    minHeight: LullPillButton._minHeight,
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: spacing.xl,
                      vertical: spacing.sm,
                    ),
                    child: Row(
                      // min + center: hugs content when loose, centers when
                      // the parent stretches it full-width.
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        if (widget.icon != null) ...<Widget>[
                          Icon(
                            widget.icon,
                            size: LullPillButton._iconSize,
                            color: foreground,
                          ),
                          SizedBox(width: spacing.sm),
                        ],
                        Text(
                          widget.label,
                          // w600 in both variants: one calm call to action,
                          // never a shout.
                          style: type.body.copyWith(
                            color: foreground,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
