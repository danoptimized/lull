import 'package:flutter/widgets.dart';

import 'package:lull/core/theme/theme.dart';

/// Three tiny slot dots for today's essentials: aurora-filled when done,
/// a hairline ring with a teal center while active, a bare ring when empty.
class SlotDots extends StatelessWidget {
  const SlotDots({
    super.key,
    required this.filled,
    required this.active,
    this.total = 3,
  });

  /// Dots at indices `< filled` render as completed (aurora fill).
  final int filled;

  /// Index of the in-progress slot; ignored when `< filled` or out of range.
  final int active;

  final int total;

  static const double _dotSize = 8;
  static const double _innerDotSize = 4;
  // Contract-fixed gap between dots; intentionally not on the spacing scale.
  static const double _gap = 6;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$filled of $total complete',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          for (var i = 0; i < total; i++) ...<Widget>[
            if (i > 0) const SizedBox(width: _gap),
            if (i < filled)
              const _Dot.filled()
            else if (i == active)
              const _Dot.active()
            else
              const _Dot.empty(),
          ],
        ],
      ),
    );
  }
}

enum _DotState { filled, active, empty }

class _Dot extends StatelessWidget {
  const _Dot.filled() : state = _DotState.filled;
  const _Dot.active() : state = _DotState.active;
  const _Dot.empty() : state = _DotState.empty;

  final _DotState state;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      width: SlotDots._dotSize,
      height: SlotDots._dotSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: state == _DotState.filled ? colors.aurora : null,
        border: state == _DotState.filled
            ? null
            : Border.all(color: colors.hairline),
      ),
      child: state == _DotState.active
          ? Center(
              child: Container(
                width: SlotDots._innerDotSize,
                height: SlotDots._innerDotSize,
                decoration: BoxDecoration(
                  color: colors.accentTeal,
                  shape: BoxShape.circle,
                ),
              ),
            )
          : null,
    );
  }
}
