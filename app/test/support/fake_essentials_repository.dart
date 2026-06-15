import 'package:lull/features/essentials/data/essentials_repository.dart';
import 'package:lull/features/essentials/domain/essential.dart';

/// In-memory [EssentialsRepository] for tests and goldens — never touches
/// Supabase. Seed it with a starting set of essentials.
class FakeEssentialsRepository implements EssentialsRepository {
  FakeEssentialsRepository([List<Essential> initial = const []])
    : _items = [...initial];

  final List<Essential> _items;

  @override
  Future<List<Essential>> fetchToday() async =>
      List<Essential>.unmodifiable(_items..sort((a, b) => a.slot - b.slot));

  @override
  Future<void> create({
    required String id,
    required int slot,
    required String title,
    required int targetPomodoros,
  }) async {
    _items.add(
      Essential(
        id: id,
        slot: slot,
        title: title,
        targetPomodoros: targetPomodoros,
      ),
    );
  }

  @override
  Future<void> update({
    required String id,
    required String title,
    required int targetPomodoros,
  }) async {
    final i = _items.indexWhere((e) => e.id == id);
    if (i >= 0) {
      _items[i] = _items[i].copyWith(
        title: title,
        targetPomodoros: targetPomodoros,
      );
    }
  }

  @override
  Future<void> setCompleted({required String id, required bool done}) async {
    final i = _items.indexWhere((e) => e.id == id);
    if (i >= 0) {
      _items[i] = _items[i].copyWith(
        completedAt: done ? DateTime.utc(2026) : null,
        clearCompletedAt: !done,
      );
    }
  }

  @override
  Future<void> delete(String id) async => _items.removeWhere((e) => e.id == id);
}
