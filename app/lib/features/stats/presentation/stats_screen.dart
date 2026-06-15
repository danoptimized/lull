import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lull/core/theme/theme.dart';
import 'package:lull/features/stats/data/stats_repository.dart';
import 'package:lull/ui/animations/lull_entrance.dart';
import 'package:lull/ui/components/lull_scaffold.dart';

/// Stats tab: points, streak, badges, and a quiet activity feed — or a gentle
/// empty state before the first session.
class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(statsControllerProvider);
    return LullScaffold(
      child: summary.when(
        loading: () => const _Loading(),
        error: (_, _) => const _Failed(),
        data: (data) {
          final isEmpty = data.points == 0 && data.recent.isEmpty;
          return isEmpty ? const _EmptyState() : _StatsBody(summary: data);
        },
      ),
    );
  }
}

class _StatsBody extends StatelessWidget {
  const _StatsBody({required this.summary});

  final StatsSummary summary;

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    final type = context.type;

    return SingleChildScrollView(
      padding: EdgeInsets.all(spacing.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LullEntrance(index: 0, child: _PointsHero(points: summary.points)),
          SizedBox(height: spacing.xl),
          LullEntrance(
            index: 1,
            child: _StreakCard(
              current: summary.currentStreak,
              longest: summary.longestStreak,
            ),
          ),
          if (summary.badges.isNotEmpty) ...[
            SizedBox(height: spacing.xxl),
            LullEntrance(index: 2, child: Text('BADGES', style: type.label)),
            SizedBox(height: spacing.md),
            LullEntrance(index: 3, child: _Badges(badges: summary.badges)),
          ],
          if (summary.recent.isNotEmpty) ...[
            SizedBox(height: spacing.xxl),
            LullEntrance(index: 4, child: Text('RECENTLY', style: type.label)),
            SizedBox(height: spacing.md),
            LullEntrance(index: 5, child: _Activity(entries: summary.recent)),
          ],
        ],
      ),
    );
  }
}

class _PointsHero extends StatelessWidget {
  const _PointsHero({required this.points});

  final int points;

  @override
  Widget build(BuildContext context) {
    final type = context.type;
    final colors = context.colors;
    // A big point total at large text scale must not burst the screen.
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.5,
      child: Column(
        children: [
          Text(
            '$points',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: type.display.copyWith(fontSize: 64),
          ),
          Text('points earned', style: type.caption),
          SizedBox(height: context.spacing.xs),
          Container(
            height: 3,
            width: 64,
            decoration: BoxDecoration(
              gradient: colors.aurora,
              borderRadius: context.radii.brPill,
            ),
          ),
        ],
      ),
    );
  }
}

class _StreakCard extends StatelessWidget {
  const _StreakCard({required this.current, required this.longest});

  final int current;
  final int longest;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final type = context.type;
    final spacing = context.spacing;
    final unit = current == 1 ? 'day' : 'days';

    return Container(
      padding: EdgeInsets.all(spacing.xl),
      decoration: BoxDecoration(
        color: colors.bg2,
        borderRadius: context.radii.brLg,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$current $unit', style: type.title),
                SizedBox(height: spacing.xs),
                Text('current streak', style: type.caption),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('$longest', style: type.heading),
              SizedBox(height: spacing.xs),
              Text('longest', style: type.caption),
            ],
          ),
        ],
      ),
    );
  }
}

class _Badges extends StatelessWidget {
  const _Badges({required this.badges});

  final List<BadgeView> badges;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final type = context.type;
    final spacing = context.spacing;
    return Wrap(
      spacing: spacing.sm,
      runSpacing: spacing.sm,
      children: [
        for (final badge in badges)
          Tooltip(
            message: badge.description,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: spacing.lg,
                vertical: spacing.sm,
              ),
              decoration: BoxDecoration(
                color: colors.accentTeal.withValues(alpha: 0.12),
                borderRadius: context.radii.brPill,
                border: Border.all(
                  color: colors.accentTeal.withValues(alpha: 0.4),
                ),
              ),
              child: Text(
                badge.name,
                style: type.caption.copyWith(color: colors.textPrimary),
              ),
            ),
          ),
      ],
    );
  }
}

class _Activity extends StatelessWidget {
  const _Activity({required this.entries});

  final List<LedgerEntry> entries;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final type = context.type;
    final spacing = context.spacing;

    return Container(
      decoration: BoxDecoration(
        color: colors.bg2,
        borderRadius: context.radii.brLg,
      ),
      child: Column(
        children: [
          for (var i = 0; i < entries.length; i++) ...[
            if (i > 0) Divider(height: 1, thickness: 1, color: colors.hairline),
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: spacing.xl,
                vertical: spacing.lg,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _entryLabel(entries[i].entryType),
                      style: type.body,
                    ),
                  ),
                  Text(_ago(entries[i].createdAt), style: type.caption),
                  SizedBox(width: spacing.lg),
                  ConstrainedBox(
                    constraints: const BoxConstraints(minWidth: 44),
                    child: Text(
                      entries[i].points > 0
                          ? '+${entries[i].points}'
                          : '${entries[i].points}',
                      textAlign: TextAlign.end,
                      style: type.body.copyWith(
                        color: entries[i].points >= 0
                            ? colors.accentTeal
                            : colors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) => Center(
    child: SizedBox(
      width: 28,
      height: 28,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        color: context.colors.accentTeal,
      ),
    ),
  );
}

class _Failed extends ConsumerWidget {
  const _Failed();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final type = context.type;
    return Center(
      child: Padding(
        padding: EdgeInsets.all(context.spacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('couldn’t load your progress', style: type.bodySoft),
            SizedBox(height: context.spacing.md),
            TextButton(
              onPressed: () => ref.invalidate(statsControllerProvider),
              child: Text(
                'try again',
                style: type.body.copyWith(color: context.colors.accentTeal),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    final type = context.type;
    return SingleChildScrollView(
      padding: EdgeInsets.all(spacing.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LullEntrance(index: 0, child: Text('your week', style: type.heading)),
          SizedBox(height: spacing.xl),
          const LullEntrance(index: 1, child: _ChartSilhouette()),
          SizedBox(height: spacing.xl),
          LullEntrance(
            index: 2,
            child: Text(
              'your story starts with one session',
              textAlign: TextAlign.center,
              style: type.bodySoft,
            ),
          ),
          SizedBox(height: spacing.lg),
          const LullEntrance(index: 3, child: Center(child: _DayChip())),
        ],
      ),
    );
  }
}

class _ChartSilhouette extends StatelessWidget {
  const _ChartSilhouette();

  static const double _height = 140;

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: spacing.xl,
        vertical: spacing.xl,
      ),
      decoration: BoxDecoration(
        color: context.colors.bg2,
        borderRadius: context.radii.brLg,
      ),
      child: RepaintBoundary(
        child: SizedBox(
          height: _height,
          width: double.infinity,
          child: CustomPaint(
            painter: _SilhouetteBarsPainter(color: context.colors.hairline),
          ),
        ),
      ),
    );
  }
}

class _SilhouetteBarsPainter extends CustomPainter {
  const _SilhouetteBarsPainter({required this.color});

  final Color color;

  static const List<double> _heights = [
    0.32,
    0.52,
    0.38,
    0.72,
    0.46,
    0.6,
    0.26,
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final count = _heights.length;
    final barWidth = size.width / (count * 2 - 1);
    final radius = Radius.circular(barWidth / 2);
    for (var i = 0; i < count; i++) {
      final barHeight = size.height * _heights[i];
      final rect = Rect.fromLTWH(
        i * barWidth * 2,
        size.height - barHeight,
        barWidth,
        barHeight,
      );
      canvas.drawRRect(RRect.fromRectAndRadius(rect, radius), paint);
    }
  }

  @override
  bool shouldRepaint(_SilhouetteBarsPainter oldDelegate) =>
      color != oldDelegate.color;
}

class _DayChip extends StatelessWidget {
  const _DayChip();

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: spacing.lg,
        vertical: spacing.sm,
      ),
      decoration: BoxDecoration(
        borderRadius: context.radii.brPill,
        border: Border.all(color: context.colors.hairline),
      ),
      child: Text('DAY 1 — GENTLY DOES IT', style: context.type.label),
    );
  }
}

String _entryLabel(String type) => switch (type) {
  'session_complete' => 'focus complete',
  'task_target_bonus' => 'task done',
  'daily_complete_bonus' => 'all three, done',
  'badge_grant' => 'badge earned',
  'streak_multiplier_adjust' => 'streak bonus',
  'future_redeem' => 'redeemed',
  _ => 'adjustment',
};

String _ago(DateTime time) {
  final d = DateTime.now().difference(time);
  if (d.inMinutes < 1) return 'just now';
  if (d.inHours < 1) return '${d.inMinutes}m ago';
  if (d.inDays < 1) return '${d.inHours}h ago';
  return '${d.inDays}d ago';
}
