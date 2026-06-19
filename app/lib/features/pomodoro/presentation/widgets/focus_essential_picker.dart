import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lull/core/theme/theme.dart';
import 'package:lull/features/essentials/application/essentials_controller.dart';
import 'package:lull/features/essentials/domain/essential.dart';

/// What the user picked in [showFocusEssentialPicker]: a specific [essential],
/// or `null` to focus without a linked task. The picker returns `null` (not a
/// [FocusChoice]) when it is dismissed without choosing anything.
@immutable
class FocusChoice {
  const FocusChoice(this.essential);

  /// The essential the next focus is for, or null for "focus without a task".
  final Essential? essential;
}

/// A calm sheet for choosing which essential the next focus session is for.
///
/// Lists today's filled essentials — the suggested one (the next unfinished)
/// wearing an accent border — plus a quiet "focus without a task" escape.
/// Returns the [FocusChoice], or null if the sheet was dismissed.
Future<FocusChoice?> showFocusEssentialPicker(BuildContext context) {
  return showModalBottomSheet<FocusChoice>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _FocusEssentialPickerSheet(),
  );
}

class _FocusEssentialPickerSheet extends ConsumerWidget {
  const _FocusEssentialPickerSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final spacing = context.spacing;
    final type = context.type;

    final essentials = ref
        .watch(essentialSlotsProvider)
        .whereType<Essential>()
        .toList();
    final suggestedId = ref.watch(nextEssentialProvider)?.id;

    return Container(
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
              Text('what are you focusing on?', style: type.heading),
              SizedBox(height: spacing.lg),
              for (var i = 0; i < essentials.length; i++) ...[
                if (i > 0) SizedBox(height: spacing.md),
                _ChoiceRow(
                  essential: essentials[i],
                  suggested: essentials[i].id == suggestedId,
                  onTap: () => Navigator.of(
                    context,
                  ).pop(FocusChoice(essentials[i])),
                ),
              ],
              SizedBox(height: spacing.lg),
              Center(
                child: TextButton(
                  onPressed: () =>
                      Navigator.of(context).pop(const FocusChoice(null)),
                  child: Text(
                    'focus without a task',
                    style: type.caption.copyWith(color: colors.textSecondary),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One selectable essential in the picker. The suggested next essential wears
/// an accent border; a finished one recedes (dimmed title + a bare check).
class _ChoiceRow extends StatelessWidget {
  const _ChoiceRow({
    required this.essential,
    required this.suggested,
    required this.onTap,
  });

  final Essential essential;
  final bool suggested;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final spacing = context.spacing;
    final type = context.type;
    final done = essential.complete;

    return Semantics(
      button: true,
      excludeSemantics: true,
      label:
          'focus on ${essential.title}, '
          '${essential.completedPomodoros} of ${essential.targetPomodoros} '
          'pomodoros${done ? ', done' : ''}${suggested ? ', suggested' : ''}',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: context.radii.brLg,
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: spacing.xl,
              vertical: spacing.lg,
            ),
            decoration: BoxDecoration(
              color: colors.bg2,
              borderRadius: context.radii.brLg,
              border: Border.all(
                color: suggested
                    ? colors.accentTeal.withValues(alpha: 0.6)
                    : colors.hairline,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        essential.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: done
                            ? type.body.copyWith(color: colors.textSecondary)
                            : type.body,
                      ),
                      SizedBox(height: spacing.xs),
                      Text(
                        done
                            ? 'done'
                            : '${essential.completedPomodoros} of '
                                  '${essential.targetPomodoros} pomodoros',
                        style: type.caption,
                      ),
                    ],
                  ),
                ),
                if (suggested) ...[
                  SizedBox(width: spacing.md),
                  Text(
                    'suggested',
                    style: type.caption.copyWith(color: colors.accentTeal),
                  ),
                ] else if (done) ...[
                  SizedBox(width: spacing.md),
                  Icon(
                    Icons.check_rounded,
                    size: 16,
                    color: colors.success,
                    semanticLabel: 'completed',
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
