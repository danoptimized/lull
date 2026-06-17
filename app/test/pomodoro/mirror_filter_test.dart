import 'package:flutter_test/flutter_test.dart';

import 'package:lull/features/pomodoro/data/session_channel.dart';
import 'package:lull/features/pomodoro/domain/remote_session.dart';

void main() {
  final now = DateTime.utc(2026, 6, 17, 12);

  RemoteSession session({
    DateTime? startedAt,
    int planned = 1500,
    String? clientId,
    DateTime? endedAt,
  }) => RemoteSession(
    id: 's',
    kind: 'focus',
    startedAt: startedAt ?? now.subtract(const Duration(minutes: 1)),
    plannedSeconds: planned,
    clientId: clientId,
    endedAt: endedAt,
  );

  test('a fresh session on another device is a live mirror', () {
    expect(isLiveMirror(session(clientId: 'other'), 'me', now), isTrue);
  });

  test('an expired session left open elsewhere is NOT mirrored', () {
    // Started 40 min ago, planned 25 → remaining 0: the "00:00 running
    // elsewhere" case from a closed tab / gone device.
    final stale = session(
      startedAt: now.subtract(const Duration(minutes: 40)),
      clientId: 'other',
    );
    expect(isLiveMirror(stale, 'me', now), isFalse);
  });

  test("this device's own session is not a mirror", () {
    expect(isLiveMirror(session(clientId: 'me'), 'me', now), isFalse);
  });

  test('an ended session is not a mirror', () {
    expect(
      isLiveMirror(session(clientId: 'other', endedAt: now), 'me', now),
      isFalse,
    );
  });
}
