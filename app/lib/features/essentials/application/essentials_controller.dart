import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lull/features/essentials/data/essentials_repository.dart';
import 'package:lull/features/essentials/domain/essential.dart';
import 'package:lull/features/profile/data/profile_repository.dart';

/// Today's essentials, loaded from Supabase. Every mutation writes through the
/// repository, then reloads so the UI reflects exactly what the server (and its
/// constraints) accepted.
class EssentialsController extends AsyncNotifier<List<Essential>> {
  EssentialsRepository get _repo => ref.read(essentialsRepositoryProvider);

  @override
  Future<List<Essential>> build() async {
    // Align the server's "today" with the device before the first query, so a
    // near-midnight create can't be rejected for the wrong local date.
    await ref.read(profileRepositoryProvider).ensureTimezone();
    return _repo.fetchToday();
  }

  Future<void> _reload() async {
    state = await AsyncValue.guard(_repo.fetchToday);
  }

  Future<void> create({
    required int slot,
    required String title,
    required int targetPomodoros,
  }) async {
    await _repo.create(
      slot: slot,
      title: title,
      targetPomodoros: targetPomodoros,
    );
    await _reload();
  }

  // Named `edit`, not `update`: AsyncNotifier already defines `update`.
  Future<void> edit({
    required String id,
    required String title,
    required int targetPomodoros,
  }) async {
    await _repo.update(id: id, title: title, targetPomodoros: targetPomodoros);
    await _reload();
  }

  Future<void> setCompleted({required String id, required bool done}) async {
    await _repo.setCompleted(id: id, done: done);
    await _reload();
  }

  Future<void> remove(String id) async {
    await _repo.delete(id);
    await _reload();
  }
}

final essentialsControllerProvider =
    AsyncNotifierProvider<EssentialsController, List<Essential>>(
      EssentialsController.new,
    );

List<Essential> _items(Ref ref) =>
    ref.watch(essentialsControllerProvider).asData?.value ??
    const <Essential>[];

/// The three positions (slots 1..3) as a fixed-length nullable list; `null` is
/// an empty slot the UI renders as a ghost.
final essentialSlotsProvider = Provider<List<Essential?>>((ref) {
  final items = _items(ref);
  Essential? bySlot(int slot) {
    for (final essential in items) {
      if (essential.slot == slot) return essential;
    }
    return null;
  }

  return [bySlot(1), bySlot(2), bySlot(3)];
});

/// Overall day progress (completed pomodoros / total target) for the ring.
final dayProgressProvider = Provider<double>((ref) {
  final items = _items(ref);
  var target = 0;
  var done = 0;
  for (final essential in items) {
    target += essential.targetPomodoros;
    done += essential.complete
        ? essential.targetPomodoros
        : essential.completedPomodoros.clamp(0, essential.targetPomodoros);
  }
  return target == 0 ? 0.0 : done / target;
});

/// The first unfinished essential, used to seed a focus session.
final nextEssentialProvider = Provider<Essential?>((ref) {
  for (final essential in _items(ref)) {
    if (!essential.complete) return essential;
  }
  return null;
});
