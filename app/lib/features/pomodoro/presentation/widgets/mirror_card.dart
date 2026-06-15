import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lull/core/theme/theme.dart';
import 'package:lull/core/time/server_clock.dart';
import 'package:lull/features/pomodoro/domain/remote_session.dart';
import 'package:lull/ui/components/progress_ring.dart';

/// A live view of a session running on another of the user's devices. Ticks
/// once a second, computing the countdown from the broadcast anchor against the
/// (skew-corrected) server clock — the same derivation the owner uses.
class MirrorCard extends ConsumerStatefulWidget {
  const MirrorCard({super.key, required this.session});

  final RemoteSession session;

  @override
  ConsumerState<MirrorCard> createState() => _MirrorCardState();
}

class _MirrorCardState extends ConsumerState<MirrorCard> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(
      const Duration(seconds: 1),
      (_) => setState(() {}),
    );
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final type = context.type;
    final spacing = context.spacing;
    final session = widget.session;
    final now = ref.read(serverClockProvider).now();
    final remaining = session.remainingSeconds(now);

    return Semantics(
      container: true,
      excludeSemantics: true,
      label:
          'a ${_phase(session.kind)} session is running on another device, '
          '${_mmss(remaining)} left',
      child: Container(
        padding: EdgeInsets.all(spacing.lg),
        decoration: BoxDecoration(
          color: colors.bg2,
          borderRadius: context.radii.brLg,
          border: Border.all(color: colors.accentTeal.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            ProgressRing(
              progress: session.progress(now),
              size: 44,
              strokeWidth: 3,
              semanticLabel: 'session running on another device',
            ),
            SizedBox(width: spacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      _PulseDot(color: colors.accentTeal),
                      SizedBox(width: spacing.sm),
                      Text('RUNNING ELSEWHERE', style: type.label),
                    ],
                  ),
                  SizedBox(height: spacing.xs),
                  Text(
                    '${_mmss(remaining)} · ${_phase(session.kind)}',
                    style: type.body,
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.only(right: spacing.sm),
              child: Text(
                session.isPaused ? 'paused' : 'on another device',
                style: type.caption,
              ),
            ),
          ],
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

String _phase(String kind) => switch (kind) {
  'short_break' => 'short break',
  'long_break' => 'a longer rest',
  _ => 'focus',
};
