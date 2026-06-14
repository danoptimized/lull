import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lull/core/theme/theme.dart';
import 'package:lull/features/essentials/application/essentials_controller.dart';
import 'package:lull/features/essentials/domain/essential.dart';
import 'package:lull/ui/components/lull_pill_button.dart';

/// Opens the add/edit sheet for one essential slot. [existing] is null when
/// filling an empty slot.
Future<void> showEssentialEditor(
  BuildContext context, {
  required int slot,
  Essential? existing,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _EssentialEditorSheet(slot: slot, existing: existing),
  );
}

class _EssentialEditorSheet extends ConsumerStatefulWidget {
  const _EssentialEditorSheet({required this.slot, this.existing});

  final int slot;
  final Essential? existing;

  @override
  ConsumerState<_EssentialEditorSheet> createState() =>
      _EssentialEditorSheetState();
}

class _EssentialEditorSheetState extends ConsumerState<_EssentialEditorSheet> {
  late final TextEditingController _title = TextEditingController(
    text: widget.existing?.title ?? '',
  );
  late int _target = widget.existing?.targetPomodoros ?? 1;
  bool _busy = false;

  Essential? get _existing => widget.existing;
  bool get _isEdit => _existing != null;

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  Future<void> _guard(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _save() async {
    final title = _title.text.trim();
    if (title.isEmpty) return;
    final controller = ref.read(essentialsControllerProvider.notifier);
    await _guard(() async {
      if (_isEdit) {
        await controller.edit(
          id: _existing!.id,
          title: title,
          targetPomodoros: _target,
        );
      } else {
        await controller.create(
          slot: widget.slot,
          title: title,
          targetPomodoros: _target,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final spacing = context.spacing;
    final type = context.type;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Container(
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
                Text(
                  _isEdit ? 'edit essential' : 'a thing for today',
                  style: type.heading,
                ),
                SizedBox(height: spacing.lg),
                TextField(
                  controller: _title,
                  autofocus: !_isEdit,
                  enabled: !_busy,
                  textCapitalization: TextCapitalization.sentences,
                  style: type.body,
                  cursorColor: colors.accentTeal,
                  onSubmitted: (_) => _save(),
                  decoration: InputDecoration(
                    hintText: 'what matters today?',
                    hintStyle: type.body.copyWith(color: colors.textFaint),
                    filled: true,
                    fillColor: colors.bg2,
                    contentPadding: EdgeInsets.all(spacing.lg),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: context.radii.brMd,
                      borderSide: BorderSide(color: colors.hairline),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: context.radii.brMd,
                      borderSide: BorderSide(color: colors.accentTeal),
                    ),
                  ),
                ),
                SizedBox(height: spacing.xl),
                _TargetStepper(
                  value: _target,
                  onChanged: _busy
                      ? null
                      : (next) => setState(() => _target = next),
                ),
                SizedBox(height: spacing.xl),
                LullPillButton(
                  label: _busy ? 'saving…' : 'save',
                  onPressed: _busy ? null : _save,
                ),
                if (_isEdit) ...[
                  SizedBox(height: spacing.sm),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: _busy
                              ? null
                              : () => _guard(
                                  () => ref
                                      .read(
                                        essentialsControllerProvider.notifier,
                                      )
                                      .setCompleted(
                                        id: _existing!.id,
                                        done: !_existing!.complete,
                                      ),
                                ),
                          child: Text(
                            _existing!.complete ? 'mark not done' : 'mark done',
                            style: type.caption.copyWith(
                              color: colors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: TextButton(
                          onPressed: _busy
                              ? null
                              : () => _guard(
                                  () => ref
                                      .read(
                                        essentialsControllerProvider.notifier,
                                      )
                                      .remove(_existing!.id),
                                ),
                          child: Text(
                            'remove',
                            style: type.caption.copyWith(color: colors.danger),
                          ),
                        ),
                      ),
                    ],
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

class _TargetStepper extends StatelessWidget {
  const _TargetStepper({required this.value, required this.onChanged});

  final int value;
  final ValueChanged<int>? onChanged;

  static const int _min = 1;
  static const int _max = 12;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final type = context.type;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('pomodoros', style: type.body),
        Row(
          children: [
            IconButton(
              onPressed: value > _min && onChanged != null
                  ? () => onChanged!(value - 1)
                  : null,
              icon: const Icon(Icons.remove_rounded),
              color: colors.textSecondary,
            ),
            SizedBox(
              width: 28,
              child: Text(
                '$value',
                textAlign: TextAlign.center,
                style: type.heading,
              ),
            ),
            IconButton(
              onPressed: value < _max && onChanged != null
                  ? () => onChanged!(value + 1)
                  : null,
              icon: const Icon(Icons.add_rounded),
              color: colors.textSecondary,
            ),
          ],
        ),
      ],
    );
  }
}
