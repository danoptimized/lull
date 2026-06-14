import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lull/features/essentials/domain/essential.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Reads and writes today's three essentials. Supabase is the source of truth;
/// the server enforces ownership (RLS), the exactly-three slot constraint, and
/// that a row's `local_date` is really today in the user's timezone.
abstract class EssentialsRepository {
  Future<List<Essential>> fetchToday();
  Future<void> create({
    required int slot,
    required String title,
    required int targetPomodoros,
  });
  Future<void> update({
    required String id,
    required String title,
    required int targetPomodoros,
  });
  Future<void> setCompleted({required String id, required bool done});
  Future<void> delete(String id);
}

/// The device's local calendar day as `yyyy-MM-dd`. Matches the server's notion
/// of "today" once the profile timezone is captured to the device zone.
String todayLocalDate() => DateFormat('yyyy-MM-dd').format(DateTime.now());

class SupabaseEssentialsRepository implements EssentialsRepository {
  SupabaseClient get _client => Supabase.instance.client;
  String get _userId => _client.auth.currentUser!.id;

  @override
  Future<List<Essential>> fetchToday() async {
    final rows = await _client
        .from('daily_essentials')
        .select()
        .eq('local_date', todayLocalDate())
        .order('slot');
    return rows.map((row) => Essential.fromRow(row)).toList(growable: false);
  }

  @override
  Future<void> create({
    required int slot,
    required String title,
    required int targetPomodoros,
  }) async {
    await _client.from('daily_essentials').insert({
      'user_id': _userId,
      'local_date': todayLocalDate(),
      'slot': slot,
      'title': title,
      'target_pomodoros': targetPomodoros,
    });
  }

  @override
  Future<void> update({
    required String id,
    required String title,
    required int targetPomodoros,
  }) async {
    await _client
        .from('daily_essentials')
        .update({'title': title, 'target_pomodoros': targetPomodoros})
        .eq('id', id);
  }

  @override
  Future<void> setCompleted({required String id, required bool done}) async {
    await _client
        .from('daily_essentials')
        .update({
          'completed_at': done
              ? DateTime.now().toUtc().toIso8601String()
              : null,
        })
        .eq('id', id);
  }

  @override
  Future<void> delete(String id) async {
    await _client.from('daily_essentials').delete().eq('id', id);
  }
}

final essentialsRepositoryProvider = Provider<EssentialsRepository>(
  (ref) => SupabaseEssentialsRepository(),
);
