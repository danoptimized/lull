import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:lull/core/motion/motion.dart';
import 'package:lull/core/theme/theme.dart';

/// Responsive navigation chrome around the tabbed branches: a quiet bottom
/// bar under 900px, a slim left rail (content capped at 560px) above it.
class LullShell extends StatelessWidget {
  const LullShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static const double _railBreakpoint = 900;
  static const double _railWidth = 72;
  static const double _barHeight = 64;
  static const double _contentMaxWidth = 560;

  void _goBranch(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final wide = MediaQuery.sizeOf(context).width >= _railBreakpoint;

    if (wide) {
      return Scaffold(
        backgroundColor: colors.bg1,
        body: Row(
          children: <Widget>[
            _NavRail(
              currentIndex: navigationShell.currentIndex,
              onSelect: _goBranch,
            ),
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: _contentMaxWidth),
                  child: navigationShell,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: colors.bg1,
      body: navigationShell,
      bottomNavigationBar: _NavBar(
        currentIndex: navigationShell.currentIndex,
        onSelect: _goBranch,
      ),
    );
  }
}

class _Destination {
  const _Destination(this.icon, this.tooltip);

  final IconData icon;
  final String tooltip;
}

// Order mirrors the router's branch order: today / stats / settings.
const List<_Destination> _destinations = <_Destination>[
  _Destination(Icons.today_rounded, 'today'),
  _Destination(Icons.bar_chart_rounded, 'stats'),
  _Destination(Icons.settings_rounded, 'settings'),
];

class _NavBar extends StatelessWidget {
  const _NavBar({required this.currentIndex, required this.onSelect});

  final int currentIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.bg1,
        border: Border(top: BorderSide(color: colors.hairline)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: LullShell._barHeight,
          child: Row(
            children: <Widget>[
              for (var i = 0; i < _destinations.length; i++)
                Expanded(
                  child: _NavIcon(
                    destination: _destinations[i],
                    selected: i == currentIndex,
                    onTap: () => onSelect(i),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavRail extends StatelessWidget {
  const _NavRail({required this.currentIndex, required this.onSelect});

  final int currentIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final spacing = context.spacing;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.bg1,
        border: Border(right: BorderSide(color: colors.hairline)),
      ),
      child: SafeArea(
        right: false,
        child: SizedBox(
          width: LullShell._railWidth,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              for (var i = 0; i < _destinations.length; i++)
                Padding(
                  padding: EdgeInsets.symmetric(vertical: spacing.md),
                  child: _NavIcon(
                    destination: _destinations[i],
                    selected: i == currentIndex,
                    onTap: () => onSelect(i),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavIcon extends ConsumerWidget {
  const _NavIcon({
    required this.destination,
    required this.selected,
    required this.onTap,
  });

  final _Destination destination;
  final bool selected;
  final VoidCallback onTap;

  static const double _dotSize = 4;
  static const double _iconSize = 24;
  static const double _inkRadius = 28;

  // Minimum hit target: in the rail the column would otherwise shrink-wrap
  // to ~24×34px (the ink radius is only a visual).
  static const double _minTarget = 48;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final motion = context.motion;
    // Selection feedback snaps under reduced motion.
    final feedback = Motion.functional(context, ref, motion.quick);
    return Semantics(
      button: true,
      selected: selected,
      child: Tooltip(
        message: destination.tooltip,
        child: Material(
          type: MaterialType.transparency,
          child: InkResponse(
            onTap: onTap,
            radius: _inkRadius,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minWidth: _minTarget,
                minHeight: _minTarget,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  AnimatedSwitcher(
                    duration: feedback,
                    switchInCurve: motion.gentleOut,
                    switchOutCurve: motion.gentleOut,
                    child: Icon(
                      destination.icon,
                      key: ValueKey<bool>(selected),
                      size: _iconSize,
                      color: selected ? colors.accentTeal : colors.textFaint,
                    ),
                  ),
                  SizedBox(height: context.spacing.xs),
                  AnimatedOpacity(
                    opacity: selected ? 1 : 0,
                    duration: feedback,
                    curve: motion.gentleOut,
                    child: Container(
                      width: _dotSize,
                      height: _dotSize,
                      decoration: BoxDecoration(
                        color: colors.accentTeal,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
