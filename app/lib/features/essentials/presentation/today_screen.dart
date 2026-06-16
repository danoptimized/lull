import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:lull/core/theme/theme.dart';
import 'package:lull/core/time/clock_sync.dart';
import 'package:lull/features/essentials/application/essentials_controller.dart';
import 'package:lull/features/essentials/presentation/widgets/essential_editor.dart';
import 'package:lull/features/essentials/presentation/widgets/slot_card.dart';
import 'package:lull/features/notifications/application/notifications_controller.dart';
import 'package:lull/features/notifications/presentation/notification_bell.dart';
import 'package:lull/features/pomodoro/application/focus_engine.dart';
import 'package:lull/features/pomodoro/application/mirror_controller.dart';
import 'package:lull/features/pomodoro/data/presence_channel.dart';
import 'package:lull/features/pomodoro/presentation/widgets/mirror_card.dart';
import 'package:lull/features/profile/application/profile_sync.dart';
import 'package:lull/features/stats/data/economy_channel.dart';
import 'package:lull/features/stats/data/stats_repository.dart';
import 'package:lull/ui/animations/lull_entrance.dart';
import 'package:lull/ui/components/lull_pill_button.dart';
import 'package:lull/ui/components/lull_scaffold.dart';
import 'package:lull/ui/components/progress_ring.dart';

/// The default tab: a time-aware greeting, today's three essentials, and one
/// calm call to action. Essentials are loaded from and synced to Supabase.
class TodayScreen extends ConsumerWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Keep account-synced settings (theme, reduced motion) flowing while the
    // authenticated app is on screen.
    ref.watch(profileSyncProvider);
    // A completed focus session advances the linked essential and mints points
    // server-side — refresh both so Today and Stats reflect it on return.
    ref.listen(focusEngineProvider.select((s) => s.completionPulse), (
      previous,
      next,
    ) {
      if (previous != null && next > previous) {
        ref.invalidate(essentialsControllerProvider);
        ref.invalidate(statsControllerProvider);
      }
    });
    // A change minted on another device (a finished session there) refreshes
    // this device's essentials + stats too.
    ref.listen(economyChangesProvider, (_, _) {
      ref.invalidate(essentialsControllerProvider);
      ref.invalidate(statsControllerProvider);
    });
    // Surface incoming notifications as a gentle toast while the app is open.
    ref.listen(notificationsProvider, (previous, next) {
      final grew = next.items.length > (previous?.items.length ?? 0);
      if (grew && next.items.isNotEmpty) {
        final n = next.items.first;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(n.body.isEmpty ? n.title : '${n.title} · ${n.body}'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: context.colors.bg2,
          ),
        );
      }
    });
    // Calibrate the clock so a mirrored countdown agrees with the device that
    // started it, and surface a session running on another device.
    ref.watch(clockSyncProvider);
    final mirror = ref.watch(mirroredSessionProvider).asData?.value;
    final essentials = ref.watch(essentialsControllerProvider);
    final spacing = context.spacing;
    // Only a hard failure with nothing cached takes over the screen; otherwise
    // the body always renders (ghost slots while the first load lands), so the
    // header and structure never flash blank.
    final failed = essentials.hasError && !essentials.hasValue;
    // First load: dim the ghost slots so they read as "loading", not an empty day.
    final loading = essentials.isLoading && !essentials.hasValue;

    return LullScaffold(
      child: Column(
        children: [
          if (mirror != null)
            Padding(
              padding: EdgeInsets.fromLTRB(
                spacing.screenPadding,
                spacing.lg,
                spacing.screenPadding,
                0,
              ),
              child: MirrorCard(session: mirror),
            ),
          Expanded(
            child: failed
                ? const _Failed()
                : Opacity(
                    opacity: loading ? 0.45 : 1,
                    child: const _EssentialsBody(),
                  ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              spacing.screenPadding,
              spacing.lg,
              spacing.screenPadding,
              spacing.screenPadding,
            ),
            child: LullEntrance(
              index: 5,
              child: SizedBox(
                width: double.infinity,
                child: LullPillButton(
                  label: 'begin a focus session',
                  onPressed: () {
                    final next = ref.read(nextEssentialProvider);
                    ref
                        .read(focusEngineProvider.notifier)
                        .selectEssential(next?.id, next?.title);
                    context.push('/focus');
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EssentialsBody extends ConsumerWidget {
  const _EssentialsBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spacing = context.spacing;
    final slots = ref.watch(essentialSlotsProvider);

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        spacing.screenPadding,
        spacing.screenPadding,
        spacing.screenPadding,
        spacing.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const LullEntrance(index: 0, child: _Header()),
          SizedBox(height: spacing.xxl),
          LullEntrance(
            index: 1,
            child: Text('THREE THINGS FOR TODAY', style: context.type.label),
          ),
          SizedBox(height: spacing.md),
          for (var i = 0; i < slots.length; i++) ...[
            if (i > 0) SizedBox(height: spacing.md),
            LullEntrance(
              index: 2 + i,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: context.radii.brLg,
                  onTap: () => showEssentialEditor(
                    context,
                    slot: i + 1,
                    existing: slots[i],
                  ),
                  child: SlotCard(essential: slots[i], slot: i + 1),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Header extends ConsumerWidget {
  const _Header();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spacing = context.spacing;
    final type = context.type;
    final colors = context.colors;
    final now = DateTime.now();
    final progress = ref.watch(dayProgressProvider);
    final devices = ref.watch(onlineDevicesProvider).asData?.value ?? 0;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_greeting(now), style: type.title),
              SizedBox(height: spacing.sm),
              Text(
                _headerDateFormat.format(now).toLowerCase(),
                style: type.caption,
              ),
              if (devices > 1) ...[
                SizedBox(height: spacing.sm),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: colors.accentTeal,
                      ),
                    ),
                    SizedBox(width: spacing.xs),
                    Text(
                      '$devices devices online',
                      style: type.caption.copyWith(color: colors.accentTeal),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        const NotificationBell(),
        SizedBox(width: spacing.sm),
        ProgressRing(progress: progress, semanticLabel: 'day progress'),
      ],
    );
  }
}

class _Failed extends ConsumerWidget {
  const _Failed();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final type = context.type;
    final spacing = context.spacing;
    return Center(
      child: Padding(
        padding: EdgeInsets.all(spacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'couldn’t reach your things',
              style: type.bodySoft,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: spacing.md),
            TextButton(
              onPressed: () => ref.invalidate(essentialsControllerProvider),
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

/// Hoisted so the header doesn't rebuild the formatter on every rebuild.
final DateFormat _headerDateFormat = DateFormat('EEEE, MMMM d');

String _greeting(DateTime now) {
  if (now.hour < 12) return 'good morning';
  if (now.hour < 17) return 'good afternoon';
  return 'good evening';
}
