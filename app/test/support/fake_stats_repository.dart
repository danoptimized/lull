import 'package:lull/features/stats/data/stats_repository.dart';

/// In-memory [StatsRepository] for tests and goldens.
class FakeStatsRepository implements StatsRepository {
  FakeStatsRepository([StatsSummary? summary]) : _summary = summary ?? _seed;

  final StatsSummary _summary;

  static final _seed = StatsSummary(
    points: 240,
    currentStreak: 4,
    longestStreak: 9,
    badges: const [
      BadgeView(
        code: 'first_focus',
        name: 'first light',
        description: 'your first focused session',
        rarity: 'common',
      ),
      BadgeView(
        code: 'seven_day_streak',
        name: 'seven mornings',
        description: 'seven days in a row',
        rarity: 'uncommon',
      ),
    ],
    recent: [
      LedgerEntry(
        entryType: 'daily_complete_bonus',
        points: 100,
        createdAt: DateTime.now().subtract(const Duration(minutes: 4)),
      ),
      LedgerEntry(
        entryType: 'task_target_bonus',
        points: 25,
        createdAt: DateTime.now().subtract(const Duration(minutes: 35)),
      ),
      LedgerEntry(
        entryType: 'session_complete',
        points: 12,
        createdAt: DateTime.now().subtract(const Duration(hours: 1)),
      ),
    ],
  );

  @override
  Future<StatsSummary> fetchSummary() async => _summary;
}
