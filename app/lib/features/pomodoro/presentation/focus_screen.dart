import 'dart:async';

import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:lull/core/audio/audio_controller.dart';
import 'package:lull/core/motion/motion.dart';
import 'package:lull/core/theme/theme.dart';
import 'package:lull/features/pomodoro/application/focus_engine.dart';
import 'package:lull/features/pomodoro/domain/focus_phase.dart';
import 'package:lull/features/pomodoro/domain/focus_state.dart';
import 'package:lull/features/pomodoro/domain/pomodoro_cycle.dart';
import 'package:lull/features/pomodoro/presentation/widgets/countdown_text.dart';
import 'package:lull/ui/animations/lull_entrance.dart';
import 'package:lull/ui/components/aurora_backdrop.dart';
import 'package:lull/ui/components/lull_pill_button.dart';
import 'package:lull/ui/components/progress_ring.dart';
import 'package:lull/ui/components/slot_dots.dart';

/// The hero focus screen (`/focus`) — full-bleed, outside the nav shell.
///
/// A quiet pre-dawn room: aurora blooms barely alive behind a single ring,
/// the clock dead center, one pill of intent at the bottom. Driven by the
/// anchor-based [focusEngineProvider]; every provider watch lives in the
/// smallest subtree that needs it, so the per-second recompute rebuilds the
/// dial alone.
class FocusScreen extends StatelessWidget {
  const FocusScreen({super.key});

  static const double _chromeMaxWidth = 720;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final spacing = context.spacing;

    return Scaffold(
      backgroundColor: colors.bg0,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const AuroraBackdrop(),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: _chromeMaxWidth),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: spacing.lg,
                    vertical: spacing.sm,
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          LullEntrance(
                            index: 0,
                            child: IconButton(
                              onPressed: () {
                                if (context.canPop()) {
                                  context.pop();
                                } else {
                                  context.go('/today');
                                }
                              },
                              tooltip: 'back',
                              color: colors.textSecondary,
                              icon: const Icon(CupertinoIcons.chevron_back),
                            ),
                          ),
                          const Spacer(),
                          const LullEntrance(index: 1, child: _AmbientToggle()),
                          SizedBox(width: spacing.sm),
                          LullEntrance(
                            index: 2,
                            child: Padding(
                              padding: EdgeInsets.only(right: spacing.md),
                              child: const _SessionDots(),
                            ),
                          ),
                        ],
                      ),
                      const Expanded(
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            LullEntrance(index: 3, child: _FocusDial()),
                            Align(
                              alignment: Alignment(0, -0.62),
                              child: _CompletionFlash(),
                            ),
                          ],
                        ),
                      ),
                      LullEntrance(
                        index: 4,
                        child: Padding(
                          padding: EdgeInsets.only(bottom: spacing.xl),
                          child: const _Controls(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Cycles the ambient bed between off and the selected soundscape.
class _AmbientToggle extends ConsumerWidget {
  const _AmbientToggle();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final soundscape = ref.watch(
      audioControllerProvider.select((s) => s.soundscape),
    );
    final on = soundscape != Soundscape.none;
    return IconButton(
      onPressed: () => ref
          .read(audioControllerProvider.notifier)
          .setSoundscape(on ? Soundscape.none : Soundscape.rain),
      tooltip: on ? 'soundscape: ${soundscape.label}' : 'soundscape: off',
      color: on ? colors.accentTeal : colors.textFaint,
      icon: Icon(
        on ? CupertinoIcons.cloud_rain : CupertinoIcons.speaker_slash,
        size: 20,
      ),
    );
  }
}

/// Session dots derived from the cycle position, so they can never drift from
/// the dial's "focus · n of 4" label.
class _SessionDots extends ConsumerWidget {
  const _SessionDots();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final (focusesBefore, isFocus) = ref.watch(
      focusEngineProvider.select((s) => (s.focusesBefore, s.isFocus)),
    );
    return SlotDots(
      filled: focusesBefore,
      active: isFocus ? 1 : 0,
      total: PomodoroCycle.focusesPerSet,
    );
  }
}

/// begin / pause / resume, plus a quiet give-up affordance while active.
class _Controls extends ConsumerWidget {
  const _Controls();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(focusEngineProvider.select((s) => s.status));
    final spacing = context.spacing;
    final type = context.type;
    final colors = context.colors;

    final label = switch (status) {
      FocusStatus.ready => 'begin',
      FocusStatus.running => 'pause',
      FocusStatus.paused => 'resume',
    };

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        LullPillButton(
          label: label,
          onPressed: () => ref.read(focusEngineProvider.notifier).toggle(),
        ),
        SizedBox(height: spacing.sm),
        // Reserve the row's height so the pill doesn't jump when it appears.
        SizedBox(
          height: 36,
          child: status == FocusStatus.ready
              ? null
              : Center(
                  child: TextButton(
                    onPressed: () =>
                        ref.read(focusEngineProvider.notifier).abort(),
                    child: Text(
                      'give up',
                      style: type.caption.copyWith(color: colors.textFaint),
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}

/// A brief, gentle word when a phase completes. Watches the completion pulse
/// and fades a single line in and out — no layout shift, never blocks taps.
class _CompletionFlash extends ConsumerStatefulWidget {
  const _CompletionFlash();

  @override
  ConsumerState<_CompletionFlash> createState() => _CompletionFlashState();
}

class _CompletionFlashState extends ConsumerState<_CompletionFlash> {
  String? _message;
  Timer? _timer;

  @override
  Widget build(BuildContext context) {
    ref.listen(focusEngineProvider.select((s) => s.completionPulse), (
      previous,
      next,
    ) {
      if (previous != null && next > previous) _show();
    });

    final type = context.type;
    final colors = context.colors;
    return IgnorePointer(
      child: AnimatedOpacity(
        opacity: _message == null ? 0 : 1,
        duration: Motion.functional(context, ref, context.motion.calm),
        curve: context.motion.gentleOut,
        child: Text(
          _message ?? '',
          style: type.heading.copyWith(color: colors.accentTeal),
        ),
      ),
    );
  }

  void _show() {
    final last = ref.read(focusEngineProvider).lastCompleted;
    setState(() {
      _message = switch (last) {
        FocusPhase.focus => "that's one.",
        FocusPhase.shortBreak => 'back to it.',
        FocusPhase.longBreak => 'well rested.',
        null => 'done.',
      };
    });
    _timer?.cancel();
    _timer = Timer(const Duration(milliseconds: 1900), () {
      if (mounted) setState(() => _message = null);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

/// The aurora ring wrapping the countdown block: phase label above, clock
/// center, the essential's title beneath.
class _FocusDial extends ConsumerWidget {
  const _FocusDial();

  static const double _diameter = 312;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(focusEngineProvider);
    final spacing = context.spacing;
    final type = context.type;
    final colors = context.colors;

    final paused = state.paused;
    final label = paused
        ? 'PAUSED'
        : (state.isFocus
                  ? '${state.phase.label} · ${state.sessionIndex} of '
                        '${state.sessionsPerSet}'
                  : state.phase.label)
              .toUpperCase();

    // The dial is a fixed circle; cap text scaling inside it so huge scales
    // soften rather than burst the ring.
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.4,
      child: SizedBox.square(
        dimension: _diameter,
        child: Stack(
          alignment: Alignment.center,
          children: [
            AnimatedOpacity(
              opacity: paused ? 0.55 : 1,
              duration: Motion.functional(context, ref, context.motion.calm),
              child: ProgressRing(
                progress: state.progress,
                size: _diameter,
                glowTip: !paused,
                semanticLabel: 'session progress',
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: type.label.copyWith(
                    color: paused ? colors.breakWarm : null,
                  ),
                ),
                SizedBox(height: spacing.md),
                RepaintBoundary(
                  child: CountdownText(seconds: state.remainingSeconds),
                ),
                SizedBox(height: spacing.md),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: spacing.xxl),
                  child: Text(
                    _subtitle(state),
                    style: type.bodySoft,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _subtitle(FocusState state) => switch (state.phase) {
    FocusPhase.focus => state.essentialTitle ?? 'deep work',
    FocusPhase.shortBreak => 'rest your eyes',
    FocusPhase.longBreak => 'stand, stretch, breathe',
  };
}
