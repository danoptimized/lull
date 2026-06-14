import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lull/features/pomodoro/domain/remote_session.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Streams the session currently running on *another* of the user's devices, or
/// null when there is none (or it's this device's own, or it ended).
abstract class SessionChannel {
  Stream<RemoteSession?> watch({
    required String userId,
    required String myDeviceId,
  });
}

class SupabaseSessionChannel implements SessionChannel {
  SupabaseClient get _client => Supabase.instance.client;

  @override
  Stream<RemoteSession?> watch({
    required String userId,
    required String myDeviceId,
  }) {
    final controller = StreamController<RemoteSession?>();
    RealtimeChannel? channel;

    void emit(Map<String, dynamic> data) {
      try {
        final session = RemoteSession.fromJson(data);
        // A mirror is an active session this device did not start.
        final isMine = session.clientId == myDeviceId;
        controller.add(session.isActive && !isMine ? session : null);
      } catch (_) {
        /* ignore malformed payloads */
      }
    }

    Future<void> start() async {
      // Reconnect reconciliation: fetch the current active session first, in
      // case a broadcast was missed while this device was away.
      try {
        final rows = await _client
            .from('pomodoro_sessions')
            .select()
            .filter('ended_at', 'is', null)
            .order('started_at', ascending: false)
            .limit(1);
        controller.add(null);
        if (rows.isNotEmpty) emit(Map<String, dynamic>.from(rows.first));
      } catch (_) {
        controller.add(null);
      }

      channel = _client.channel(
        'session:$userId',
        opts: const RealtimeChannelConfig(private: true),
      );
      channel!
          .onBroadcast(
            event: 'session',
            callback: (payload) {
              final data = _payload(payload);
              if (data != null) emit(data);
            },
          )
          .subscribe();
    }

    controller.onListen = start;
    controller.onCancel = () async {
      final c = channel;
      if (c != null) await _client.removeChannel(c);
    };
    return controller.stream;
  }

  // Broadcasts sent from the database arrive with the anchor fields either at
  // the top level or nested under `payload`, depending on transport — accept both.
  Map<String, dynamic>? _payload(Map<String, dynamic> payload) {
    if (payload['id'] != null) return payload;
    final inner = payload['payload'];
    if (inner is Map) return Map<String, dynamic>.from(inner);
    return null;
  }
}

final sessionChannelProvider = Provider<SessionChannel>(
  (ref) => SupabaseSessionChannel(),
);
