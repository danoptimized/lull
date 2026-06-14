import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lull/features/auth/application/auth_controller.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Emits whenever the user's economy changes on the server — from *any* device.
/// Lets a watching device refresh its stats and essentials when another device
/// finishes a session (ledger insert) or earns a badge. Broadcast from the
/// database to `economy:<uid>` — the same proven path as the session mirror.
abstract class EconomyChannel {
  Stream<void> changes(String userId);
}

class SupabaseEconomyChannel implements EconomyChannel {
  SupabaseClient get _client => Supabase.instance.client;

  @override
  Stream<void> changes(String userId) {
    final controller = StreamController<void>();
    RealtimeChannel? channel;

    controller.onListen = () {
      channel = _client
          .channel(
            'economy:$userId',
            opts: const RealtimeChannelConfig(private: true),
          )
          .onBroadcast(event: 'economy', callback: (_) => controller.add(null))
          .subscribe();
    };
    controller.onCancel = () async {
      final c = channel;
      if (c != null) await _client.removeChannel(c);
    };
    return controller.stream;
  }
}

final economyChannelProvider = Provider<EconomyChannel>(
  (ref) => SupabaseEconomyChannel(),
);

/// Fires on remote economy changes; the UI listens and refreshes.
final economyChangesProvider = StreamProvider<void>((ref) {
  final user = ref.watch(authControllerProvider);
  if (user == null) return const Stream<void>.empty();
  return ref.watch(economyChannelProvider).changes(user.id);
});
