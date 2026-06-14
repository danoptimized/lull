import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lull/core/theme/theme.dart';
import 'package:lull/features/notifications/application/notifications_controller.dart';
import 'package:lull/features/notifications/domain/app_notification.dart';

/// A bell with an unread dot; opens the notification center and marks read.
class NotificationBell extends ConsumerWidget {
  const NotificationBell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final unread = ref.watch(notificationsProvider.select((s) => s.unread));

    return Stack(
      alignment: Alignment.center,
      children: [
        IconButton(
          onPressed: () => _open(context, ref),
          tooltip: unread > 0 ? '$unread new notifications' : 'notifications',
          color: colors.textSecondary,
          icon: const Icon(CupertinoIcons.bell),
        ),
        if (unread > 0)
          Positioned(
            top: 10,
            right: 10,
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colors.accentTeal,
                border: Border.all(color: colors.bg1, width: 1.5),
              ),
            ),
          ),
      ],
    );
  }

  void _open(BuildContext context, WidgetRef ref) {
    ref.read(notificationsProvider.notifier).markAllRead();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _NotificationSheet(),
    );
  }
}

class _NotificationSheet extends ConsumerWidget {
  const _NotificationSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final spacing = context.spacing;
    final type = context.type;
    final items = ref.watch(notificationsProvider.select((s) => s.items));

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.6,
      ),
      decoration: BoxDecoration(
        color: colors.bg1,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(context.radii.lg),
        ),
        border: Border(top: BorderSide(color: colors.hairline)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.all(spacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colors.hairline,
                    borderRadius: context.radii.brPill,
                  ),
                ),
              ),
              SizedBox(height: spacing.lg),
              Text('notifications', style: type.heading),
              SizedBox(height: spacing.lg),
              if (items.isEmpty)
                Padding(
                  padding: EdgeInsets.symmetric(vertical: spacing.xxl),
                  child: Text(
                    'nothing yet — your wins will land here',
                    textAlign: TextAlign.center,
                    style: type.bodySoft,
                  ),
                )
              else
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: items.length,
                    separatorBuilder: (_, _) => SizedBox(height: spacing.md),
                    itemBuilder: (_, i) => _NotificationTile(items[i]),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile(this.notification);

  final AppNotification notification;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final type = context.type;
    final spacing = context.spacing;
    return Container(
      padding: EdgeInsets.all(spacing.lg),
      decoration: BoxDecoration(
        color: colors.bg2,
        borderRadius: context.radii.brMd,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(notification.title, style: type.body),
                if (notification.body.isNotEmpty) ...[
                  SizedBox(height: spacing.xs),
                  Text(notification.body, style: type.caption),
                ],
              ],
            ),
          ),
          SizedBox(width: spacing.md),
          Text(relativeTime(notification.createdAt), style: type.caption),
        ],
      ),
    );
  }
}

String relativeTime(DateTime time) {
  final d = DateTime.now().difference(time);
  if (d.inMinutes < 1) return 'now';
  if (d.inHours < 1) return '${d.inMinutes}m';
  if (d.inDays < 1) return '${d.inHours}h';
  return '${d.inDays}d';
}
