import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:lull/core/theme/theme.dart';
import 'package:lull/features/pomodoro/application/focus_engine.dart';
import 'package:lull/features/pomodoro/domain/focus_phase.dart';
import 'package:lull/features/pomodoro/domain/focus_state.dart';
import 'package:lull/ui/components/progress_ring.dart';

/// A prominent, tappable banner shown on Today while *this device* has a focus
/// session running or paused — so backing out of the focus screen never hides
/// that a session is still live. Tapping it returns to the focus screen.
///
/// Renders nothing while no session is active, so it can sit unconditionally at
/// the top of the Today column without disturbing the resting layout. The live
/// countdown comes straight from the anchor-based [focusEngineProvider], which
/// already recomputes remaining time each second.
class ActiveSessionCard extends ConsumerWidget {
  const ActiveSessionCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final (status, phase, remaining, progress, essentialTitle) = ref.watch(
      focusEngineProvider.select(
        (s) => (
          s.status,
          s.phase,
          s.remainingSeconds,
          s.progress,
          s.essentialTitle,
        ),
      ),
    );
    if (status == FocusStatus.ready) return const SizedBox.shrink();

    final colors = context.colors;
    final type = context.type;
    final spacing = context.spacing;
    final paused = status == FocusStatus.paused;
    final isFocus = phase == FocusPhase.focus;
    final accent = paused ? colors.breakWarm : colors.accentTeal;

    final heading = paused
        ? 'PAUSED'
        : (isFocus ? 'FOCUS IN PROGRESS' : 'ON A BREAK');
    final detail = isFocus
        ? (essentialTitle ?? 'deep work')
        : switch (phase) {
            FocusPhase.shortBreak => 'rest your eyes',
            FocusPhase.longBreak => 'stand, stretch, breathe',
            FocusPhase.focus => 'deep work',
          };

    return Padding(
      // Matches the mirror card's seat: it sits in the same spot at the top.
      padding: EdgeInsets.fromLTRB(
        spacing.screenPadding,
        spacing.lg,
        spacing.screenPadding,
        0,
      ),
      child: MediaQuery.withClampedTextScaling(
        // Keep the countdown legible without letting huge text clip the card.
        maxScaleFactor: 1.3,
        child: Semantics(
          container: true,
          button: true,
          excludeSemantics: true,
          label:
              '$heading, ${_mmss(remaining)} left, $detail. tap to return to '
              'your session.',
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => context.push('/focus'),
              borderRadius: context.radii.brLg,
              child: Container(
                padding: EdgeInsets.all(spacing.lg),
                decoration: BoxDecoration(
                  color: colors.bg2,
                  borderRadius: context.radii.brLg,
                  border: Border.all(color: accent.withValues(alpha: 0.35)),
                ),
                child: Row(
                  children: [
                    ProgressRing(
                      progress: progress,
                      size: 44,
                      strokeWidth: 3,
                      glowTip: !paused,
                      semanticLabel: 'session progress',
                    ),
                    SizedBox(width: spacing.lg),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              if (!paused) ...[
                                _PulseDot(color: accent),
                                SizedBox(width: spacing.sm),
                              ],
                              Text(
                                heading,
                                style: type.label.copyWith(
                                  color: paused ? accent : null,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: spacing.xs),
                          Text(
                            '${_mmss(remaining)} · $detail',
                            style: type.body,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: spacing.sm),
                    Text(
                      'tap to return',
                      style: type.caption.copyWith(color: colors.accentTeal),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PulseDot extends StatelessWidget {
  const _PulseDot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 7,
      height: 7,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}

String _mmss(int seconds) {
  final m = (seconds ~/ 60).toString().padLeft(2, '0');
  final s = (seconds % 60).toString().padLeft(2, '0');
  return '$m:$s';
}
