import 'package:flutter/foundation.dart';

/// The four notification kinds, each mapping to a `devices` opt-in column and
/// the calm copy shown in settings. The [column] strings match the database.
enum NotificationCategory {
  timer('notify_timer', 'timer transitions', 'when a focus or break begins and ends'),
  essentials(
    'notify_essentials',
    'daily essentials',
    'a gentle nudge toward today’s three',
  ),
  streak('notify_streak', 'streak at risk', 'a heads-up before a streak slips'),
  rewards('notify_rewards', 'rewards', 'badges earned and days completed');

  const NotificationCategory(this.column, this.title, this.blurb);

  final String column;
  final String title;
  final String blurb;
}

/// This device's per-category opt-ins. Defaults to all-on, matching the
/// server column defaults.
@immutable
class DeviceNotificationPrefs {
  const DeviceNotificationPrefs({
    this.timer = true,
    this.essentials = true,
    this.streak = true,
    this.rewards = true,
  });

  final bool timer;
  final bool essentials;
  final bool streak;
  final bool rewards;

  bool of(NotificationCategory category) => switch (category) {
    NotificationCategory.timer => timer,
    NotificationCategory.essentials => essentials,
    NotificationCategory.streak => streak,
    NotificationCategory.rewards => rewards,
  };

  DeviceNotificationPrefs withCategory(
    NotificationCategory category,
    bool value,
  ) => DeviceNotificationPrefs(
    timer: category == NotificationCategory.timer ? value : timer,
    essentials: category == NotificationCategory.essentials ? value : essentials,
    streak: category == NotificationCategory.streak ? value : streak,
    rewards: category == NotificationCategory.rewards ? value : rewards,
  );
}
