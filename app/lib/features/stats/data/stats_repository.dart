import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// A badge the user has earned.
class BadgeView {
  const BadgeView({
    required this.code,
    required this.name,
    required this.description,
    required this.rarity,
  });

  final String code;
  final String name;
  final String description;
  final String rarity;
}

/// One entry from the points ledger, for the activity feed.
class LedgerEntry {
  const LedgerEntry({
    required this.entryType,
    required this.points,
    required this.createdAt,
  });

  final String entryType;
  final int points;
  final DateTime createdAt;
}

/// Everything the Stats screen shows, in one snapshot.
class StatsSummary {
  const StatsSummary({
    required this.points,
    required this.currentStreak,
    required this.longestStreak,
    required this.badges,
    required this.recent,
  });

  static const empty = StatsSummary(
    points: 0,
    currentStreak: 0,
    longestStreak: 0,
    badges: [],
    recent: [],
  );

  final int points;
  final int currentStreak;
  final int longestStreak;
  final List<BadgeView> badges;
  final List<LedgerEntry> recent;
}

abstract class StatsRepository {
  Future<StatsSummary> fetchSummary();
}

class SupabaseStatsRepository implements StatsRepository {
  SupabaseClient get _client => Supabase.instance.client;

  @override
  Future<StatsSummary> fetchSummary() async {
    // RLS scopes every read to the signed-in user.
    final balanceRows = await _client
        .from('points_ledger')
        .select('balance_after')
        .order('id', ascending: false)
        .limit(1);
    final points = balanceRows.isEmpty
        ? 0
        : (balanceRows.first['balance_after'] as num).toInt();

    final streak = await _client
        .from('streaks')
        .select('current_len, longest_len')
        .maybeSingle();

    final badgeRows = await _client
        .from('user_badges')
        .select('granted_at, badges(code, name, description, rarity)')
        .order('granted_at', ascending: false);

    final recentRows = await _client
        .from('points_ledger')
        .select('entry_type, points, created_at')
        .order('id', ascending: false)
        .limit(15);

    return StatsSummary(
      points: points,
      currentStreak: (streak?['current_len'] as num?)?.toInt() ?? 0,
      longestStreak: (streak?['longest_len'] as num?)?.toInt() ?? 0,
      badges: badgeRows
          .map((row) {
            final b = row['badges'] as Map<String, dynamic>;
            return BadgeView(
              code: b['code'] as String,
              name: b['name'] as String,
              description: b['description'] as String,
              rarity: b['rarity'] as String,
            );
          })
          .toList(growable: false),
      recent: recentRows
          .map(
            (row) => LedgerEntry(
              entryType: row['entry_type'] as String,
              points: (row['points'] as num).toInt(),
              createdAt: DateTime.parse(row['created_at'] as String),
            ),
          )
          .toList(growable: false),
    );
  }
}

final statsRepositoryProvider = Provider<StatsRepository>(
  (ref) => SupabaseStatsRepository(),
);

final statsControllerProvider = FutureProvider<StatsSummary>(
  (ref) => ref.watch(statsRepositoryProvider).fetchSummary(),
);
