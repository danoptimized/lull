import 'package:flutter_test/flutter_test.dart';
import 'package:lull/features/pomodoro/domain/remote_session.dart';

void main() {
  Map<String, dynamic> payload({
    String started = '2026-06-14T09:00:00.000Z',
    int planned = 1500,
    List<Map<String, dynamic>> pauses = const [],
    String? ended,
    String? clientId = 'device-a',
  }) {
    final map = <String, dynamic>{
      'id': 'sess-1',
      'kind': 'focus',
      'started_at': started,
      'planned_seconds': planned,
      'pause_intervals': pauses,
      'client_id': clientId,
    };
    if (ended != null) map['ended_at'] = ended;
    return map;
  }

  test('parses the server wire shape', () {
    final s = RemoteSession.fromJson(payload());
    expect(s.id, 'sess-1');
    expect(s.isFocus, isTrue);
    expect(s.isActive, isTrue);
    expect(s.clientId, 'device-a');
    expect(s.plannedSeconds, 1500);
  });

  test('remaining derives from server time like the owner', () {
    final s = RemoteSession.fromJson(payload());
    final start = DateTime.parse('2026-06-14T09:00:00.000Z');
    expect(s.remainingSeconds(start), 1500);
    expect(s.remainingSeconds(start.add(const Duration(minutes: 5))), 1200);
    expect(s.remainingSeconds(start.add(const Duration(minutes: 25))), 0);
    expect(s.remainingSeconds(start.add(const Duration(minutes: 40))), 0);
  });

  test('a closed pause is excluded; an open pause freezes the countdown', () {
    final start = DateTime.parse('2026-06-14T09:00:00.000Z');
    final closed = RemoteSession.fromJson(
      payload(
        pauses: [
          {
            'start': '2026-06-14T09:00:20.000Z',
            'end': '2026-06-14T09:00:50.000Z',
          },
        ],
      ),
    );
    // 100s elapsed minus a 30s pause = 70s of progress.
    expect(
      closed.remainingSeconds(start.add(const Duration(seconds: 100))),
      1430,
    );

    final open = RemoteSession.fromJson(
      payload(
        pauses: [
          {'start': '2026-06-14T09:01:00.000Z'},
        ],
      ),
    );
    expect(open.isPaused, isTrue);
    final atPause = open.remainingSeconds(
      start.add(const Duration(seconds: 60)),
    );
    final later = open.remainingSeconds(start.add(const Duration(minutes: 10)));
    expect(atPause, 1440);
    expect(later, 1440);
  });

  test('ended sessions are inactive', () {
    final s = RemoteSession.fromJson(
      payload(ended: '2026-06-14T09:25:00.000Z'),
    );
    expect(s.isActive, isFalse);
  });
}
