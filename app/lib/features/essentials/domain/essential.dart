import 'package:flutter/foundation.dart';

/// One of today's three essentials — the only unit of planning in Lull.
///
/// Mirrors a `daily_essentials` row. [slot] is 1..3 and is the stable identity
/// of a position in the day; the server's unique `(user, local_date, slot)`
/// constraint is what makes "exactly three" impossible to exceed.
@immutable
class Essential {
  const Essential({
    required this.id,
    required this.slot,
    required this.title,
    required this.targetPomodoros,
    this.completedPomodoros = 0,
    this.completedAt,
  });

  factory Essential.fromRow(Map<String, dynamic> row) => Essential(
    id: row['id'] as String,
    slot: (row['slot'] as num).toInt(),
    title: row['title'] as String,
    targetPomodoros: (row['target_pomodoros'] as num).toInt(),
    completedPomodoros: (row['completed_pomodoros'] as num?)?.toInt() ?? 0,
    completedAt: row['completed_at'] == null
        ? null
        : DateTime.parse(row['completed_at'] as String),
  );

  final String id;
  final int slot;
  final String title;
  final int targetPomodoros;
  final int completedPomodoros;
  final DateTime? completedAt;

  /// Done either by hitting the pomodoro target or by being marked complete.
  bool get complete =>
      completedAt != null || completedPomodoros >= targetPomodoros;

  Essential copyWith({
    String? title,
    int? targetPomodoros,
    int? completedPomodoros,
    DateTime? completedAt,
    bool clearCompletedAt = false,
  }) => Essential(
    id: id,
    slot: slot,
    title: title ?? this.title,
    targetPomodoros: targetPomodoros ?? this.targetPomodoros,
    completedPomodoros: completedPomodoros ?? this.completedPomodoros,
    completedAt: clearCompletedAt ? null : (completedAt ?? this.completedAt),
  );
}
