import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lull/core/audio/audio_controller.dart';
import 'package:lull/core/config/app_prefs.dart';
import 'package:lull/core/feedback/haptics.dart';
import 'package:lull/core/theme/theme.dart';
import 'package:lull/features/auth/application/auth_controller.dart';
import 'package:lull/features/notifications/application/device_registration.dart';
import 'package:lull/features/notifications/domain/notification_category.dart';
import 'package:lull/ui/animations/lull_entrance.dart';
import 'package:lull/ui/components/lull_scaffold.dart';

/// Settings tab, M0: appearance controls (functional, app-local) and a
/// small "about" footer.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spacing = context.spacing;
    final type = context.type;

    return LullScaffold(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(spacing.screenPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LullEntrance(index: 0, child: Text('settings', style: type.title)),
            SizedBox(height: spacing.xxl),
            LullEntrance(
              index: 1,
              child: Text('APPEARANCE', style: type.label),
            ),
            SizedBox(height: spacing.md),
            const LullEntrance(index: 2, child: _AppearanceCard()),
            SizedBox(height: spacing.xxl),
            LullEntrance(
              index: 3,
              child: Text('SOUND & FEEL', style: type.label),
            ),
            SizedBox(height: spacing.md),
            const LullEntrance(index: 4, child: _SoundFeelCard()),
            SizedBox(height: spacing.xxl),
            LullEntrance(
              index: 5,
              child: Text('NOTIFICATIONS', style: type.label),
            ),
            SizedBox(height: spacing.md),
            const LullEntrance(index: 6, child: _NotificationsCard()),
            SizedBox(height: spacing.xxl),
            LullEntrance(index: 7, child: Text('ACCOUNT', style: type.label)),
            SizedBox(height: spacing.md),
            const LullEntrance(index: 8, child: _AccountCard()),
            SizedBox(height: spacing.xxl),
            LullEntrance(
              index: 9,
              child: Text('ABOUT LULL', style: type.label),
            ),
            SizedBox(height: spacing.md),
            const LullEntrance(index: 10, child: _AboutFooter()),
          ],
        ),
      ),
    );
  }
}

class _AppearanceCard extends ConsumerWidget {
  const _AppearanceCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final spacing = context.spacing;
    final type = context.type;

    return Container(
      decoration: BoxDecoration(
        color: colors.bg2,
        borderRadius: context.radii.brLg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              spacing.xl,
              spacing.xl,
              spacing.xl,
              spacing.lg,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('theme', style: type.body),
                SizedBox(height: spacing.md),
                SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<ThemeMode>(
                    segments: const [
                      ButtonSegment(
                        value: ThemeMode.system,
                        label: Text('system'),
                      ),
                      ButtonSegment(
                        value: ThemeMode.light,
                        label: Text('light'),
                      ),
                      ButtonSegment(value: ThemeMode.dark, label: Text('dark')),
                    ],
                    selected: {ref.watch(themeModeProvider)},
                    onSelectionChanged: (selection) => ref
                        .read(themeModeProvider.notifier)
                        .set(selection.first),
                    showSelectedIcon: false,
                    style: _segmentedStyle(context),
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, thickness: 1, color: colors.hairline),
          SwitchListTile(
            value: ref.watch(reducedMotionProvider),
            onChanged: (value) =>
                ref.read(reducedMotionProvider.notifier).set(value),
            title: Text('reduce motion', style: type.body),
            subtitle: Text(
              'stills the breathing and drift',
              style: type.caption,
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: spacing.xl,
              vertical: spacing.sm,
            ),
          ),
        ],
      ),
    );
  }
}

/// Shared styling for the small segmented controls in settings.
ButtonStyle _segmentedStyle(BuildContext context) {
  final colors = context.colors;
  return ButtonStyle(
    textStyle: WidgetStatePropertyAll(context.type.caption),
    foregroundColor: WidgetStateProperty.resolveWith(
      (states) => states.contains(WidgetState.selected)
          ? colors.textPrimary
          : colors.textSecondary,
    ),
    backgroundColor: WidgetStateProperty.resolveWith(
      (states) => states.contains(WidgetState.selected)
          ? colors.accentTeal.withValues(alpha: 0.14)
          : Colors.transparent,
    ),
    overlayColor: WidgetStatePropertyAll(
      colors.accentTeal.withValues(alpha: 0.06),
    ),
    side: WidgetStatePropertyAll(BorderSide(color: colors.hairline)),
  );
}

class _SoundFeelCard extends ConsumerWidget {
  const _SoundFeelCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final spacing = context.spacing;
    final type = context.type;
    final audio = ref.watch(audioControllerProvider);

    return Container(
      decoration: BoxDecoration(
        color: colors.bg2,
        borderRadius: context.radii.brLg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              spacing.xl,
              spacing.xl,
              spacing.xl,
              spacing.lg,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('soundscape', style: type.body),
                SizedBox(height: spacing.md),
                SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<Soundscape>(
                    segments: const [
                      ButtonSegment(
                        value: Soundscape.none,
                        label: Text('none'),
                      ),
                      ButtonSegment(
                        value: Soundscape.rain,
                        label: Text('rain'),
                      ),
                    ],
                    selected: {audio.soundscape},
                    onSelectionChanged: (selection) => ref
                        .read(audioControllerProvider.notifier)
                        .setSoundscape(selection.first),
                    showSelectedIcon: false,
                    style: _segmentedStyle(context),
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, thickness: 1, color: colors.hairline),
          SwitchListTile(
            value: audio.sfxEnabled,
            onChanged: (value) =>
                ref.read(audioControllerProvider.notifier).setSfxEnabled(value),
            title: Text('sound effects', style: type.body),
            subtitle: Text(
              'soft cues as sessions begin and end',
              style: type.caption,
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: spacing.xl,
              vertical: spacing.sm,
            ),
          ),
          Divider(height: 1, thickness: 1, color: colors.hairline),
          SwitchListTile(
            value: ref.watch(hapticsEnabledProvider),
            onChanged: (value) =>
                ref.read(hapticsEnabledProvider.notifier).set(value),
            title: Text('haptics', style: type.body),
            subtitle: Text('a gentle tap on transitions', style: type.caption),
            contentPadding: EdgeInsets.symmetric(
              horizontal: spacing.xl,
              vertical: spacing.sm,
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationsCard extends ConsumerWidget {
  const _NotificationsCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final spacing = context.spacing;
    final type = context.type;
    final prefsAsync = ref.watch(devicePrefsControllerProvider);
    final prefs = prefsAsync.value ?? const DeviceNotificationPrefs();
    final loading = prefsAsync.isLoading;

    return Container(
      decoration: BoxDecoration(
        color: colors.bg2,
        borderRadius: context.radii.brLg,
      ),
      child: Column(
        children: [
          for (final (index, category)
              in NotificationCategory.values.indexed) ...[
            if (index > 0)
              Divider(height: 1, thickness: 1, color: colors.hairline),
            SwitchListTile(
              value: prefs.of(category),
              onChanged: loading
                  ? null
                  : (value) => ref
                        .read(devicePrefsControllerProvider.notifier)
                        .toggle(category, value),
              title: Text(category.title, style: type.body),
              subtitle: Text(category.blurb, style: type.caption),
              contentPadding: EdgeInsets.symmetric(
                horizontal: spacing.xl,
                vertical: spacing.sm,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AccountCard extends ConsumerWidget {
  const _AccountCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final spacing = context.spacing;
    final type = context.type;
    final email = ref.watch(authControllerProvider)?.email;

    return Container(
      decoration: BoxDecoration(
        color: colors.bg2,
        borderRadius: context.radii.brLg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              spacing.xl,
              spacing.xl,
              spacing.xl,
              spacing.lg,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('signed in as', style: type.caption),
                SizedBox(height: spacing.xs),
                Text(email ?? 'your account', style: type.body),
              ],
            ),
          ),
          Divider(height: 1, thickness: 1, color: colors.hairline),
          ListTile(
            onTap: () => ref.read(authControllerProvider.notifier).signOut(),
            title: Text('sign out', style: type.body),
            contentPadding: EdgeInsets.symmetric(horizontal: spacing.xl),
          ),
          Divider(height: 1, thickness: 1, color: colors.hairline),
          ListTile(
            onTap: () => _confirmDeleteAccount(context, ref),
            title: Text(
              'delete account',
              style: type.body.copyWith(color: colors.danger),
            ),
            subtitle: Text(
              'permanently erase your account and data',
              style: type.caption,
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: spacing.xl),
          ),
        ],
      ),
    );
  }
}

/// Confirm + perform irreversible account deletion. On success the auth stream
/// flips to signed-out and the router returns to sign-in on its own.
Future<void> _confirmDeleteAccount(BuildContext context, WidgetRef ref) async {
  final colors = context.colors;
  final type = context.type;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: colors.bg2,
      title: Text('delete account?', style: type.heading),
      content: Text(
        'this permanently erases your account and all your data — essentials, '
        'sessions, points, and badges. it can’t be undone.',
        style: type.body,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text(
            'cancel',
            style: type.body.copyWith(color: colors.textSecondary),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: Text(
            'delete',
            style: type.body.copyWith(color: colors.danger),
          ),
        ),
      ],
    ),
  );
  if (confirmed != true) return;
  try {
    await ref.read(authControllerProvider.notifier).deleteAccount();
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('couldn’t delete your account — try again')),
      );
    }
  }
}

class _AboutFooter extends StatelessWidget {
  const _AboutFooter();

  @override
  Widget build(BuildContext context) {
    final type = context.type;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'lull · version 0.1.0',
          style: type.caption.copyWith(color: context.colors.textFaint),
        ),
        SizedBox(height: context.spacing.sm),
        Text('a quiet place for your three things.', style: type.bodySoft),
      ],
    );
  }
}
