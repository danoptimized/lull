import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lull/core/time/server_clock.dart';
import 'package:lull/core/util/ids.dart';
import 'package:lull/features/pomodoro/application/session_cues.dart';
import 'package:lull/features/pomodoro/data/session_api.dart';
import 'package:lull/features/pomodoro/data/session_repository.dart';
import 'package:lull/features/pomodoro/domain/focus_phase.dart';
import 'package:lull/features/pomodoro/domain/focus_session.dart';
import 'package:lull/features/pomodoro/domain/focus_state.dart';
import 'package:lull/features/pomodoro/domain/pomodoro_cycle.dart';

/// Forwards app-resume to a callback without forcing the engine to be a
/// [WidgetsBindingObserver] itself.
class _ResumeObserver with WidgetsBindingObserver {
  _ResumeObserver(this._onResumed);

  final VoidCallback _onResumed;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _onResumed();
  }
}

/// The local-first pomodoro engine.
///
/// Time is anchored, never counted: while a session runs, a heartbeat timer
/// only *recomputes* remaining time from the session's `startedAt`. A missed
/// tick (backgrounded tab, slept device) is harmless — the next recompute, or
/// the app-resume hook, snaps straight to the truth and completes the session
/// if its time has passed. The repository persists the active anchor so even a
/// killed-and-relaunched app rejoins a running session.
class FocusEngine extends Notifier<FocusState> {
  Timer? _ticker;
  bool _hydrated = false;
  bool _finalizing = false;

  ServerClock get _clock => ref.read(serverClockProvider);
  SessionRepository get _repo => ref.read(sessionRepositoryProvider);
  SessionCues get _cues => ref.read(sessionCuesProvider);
  SessionApi get _api => ref.read(sessionApiProvider);

  @override
  FocusState build() {
    final observer = _ResumeObserver(_onResumed);
    // Guarded: pure unit tests may not have a binding initialized.
    try {
      WidgetsBinding.instance.addObserver(observer);
    } catch (_) {}

    ref.onDispose(() {
      _ticker?.cancel();
      try {
        WidgetsBinding.instance.removeObserver(observer);
      } catch (_) {}
    });

    // Rejoin any session left running before this launch.
    Future.microtask(_hydrate);

    return FocusState.ready(FocusPhase.focus, focusesBefore: 0);
  }

  DateTime get _now => _clock.now().toUtc();

  /// Choose which essential the next focus is for. Ignored once a session is
  /// underway so it can't be retargeted mid-run.
  void selectEssential(String? id, String? title) {
    if (!state.ready || !state.isFocus) return;
    state = state.copyWith(essentialId: id, essentialTitle: title);
  }

  Future<void> begin() async {
    if (!state.ready) return;
    final now = _now;
    final isFocus = state.isFocus;
    final session = FocusSession(
      id: newUuidV4(),
      kind: state.phase,
      startedAt: now,
      plannedSeconds: state.plannedSeconds,
      idempotencyKey: newUuidV4(),
      focusesBefore: state.focusesBefore,
      createdAt: now,
      essentialId: isFocus ? state.essentialId : null,
      essentialTitle: isFocus ? state.essentialTitle : null,
    );
    state = state.copyWith(
      status: FocusStatus.running,
      session: session,
      remainingSeconds: session.remainingSeconds(now),
    );
    await _repo.saveActive(session);
    _startTicker();
    _cues.onBegin(session.kind);

    // Propose to the server; on success the session becomes creditable. The
    // local countdown already runs from its own anchor, so there's no wait —
    // we just link the server id back in if this session is still the live one.
    final result = await _api.start(
      idempotencyKey: session.idempotencyKey,
      kind: session.kind,
      plannedSeconds: session.plannedSeconds,
      essentialId: session.essentialId,
      clientId: session.id,
    );
    if (result != null && state.session?.id == session.id) {
      final linked = state.session!.copyWith(serverId: result.serverId);
      state = state.copyWith(session: linked);
      await _repo.saveActive(linked);
    }
  }

  Future<void> pause() async {
    final session = state.session;
    if (!state.running || session == null) return;
    final now = _now;
    final paused = session.copyWith(
      pauses: [
        ...session.pauses,
        PauseInterval(startedAt: now),
      ],
      rewardVoided: true,
    );
    _stopTicker();
    state = state.copyWith(
      status: FocusStatus.paused,
      session: paused,
      rewardVoided: true,
      remainingSeconds: paused.remainingSeconds(now),
    );
    await _repo.saveActive(paused);
    _cues.onPause();
    final serverId = paused.serverId;
    if (serverId != null) unawaited(_api.pause(serverId));
  }

  Future<void> resume() async {
    final session = state.session;
    if (!state.paused || session == null || session.pauses.isEmpty) return;
    final now = _now;
    final pauses = [...session.pauses];
    pauses[pauses.length - 1] = pauses.last.close(now);
    final resumed = session.copyWith(pauses: pauses);
    state = state.copyWith(
      status: FocusStatus.running,
      session: resumed,
      remainingSeconds: resumed.remainingSeconds(now),
    );
    await _repo.saveActive(resumed);
    _startTicker();
    _cues.onResume();
    final serverId = resumed.serverId;
    if (serverId != null) unawaited(_api.resume(serverId));
  }

  void toggle() {
    switch (state.status) {
      case FocusStatus.ready:
        unawaited(begin());
      case FocusStatus.running:
        unawaited(pause());
      case FocusStatus.paused:
        unawaited(resume());
    }
  }

  /// Give up the current session; the phase resets to its full length, ready to
  /// begin again. Nothing is rewarded.
  Future<void> abort() async {
    final session = state.session;
    _stopTicker();
    if (session != null) {
      final now = _now;
      final closed = session.isPaused
          ? session.copyWith(
              pauses: [
                ...session.pauses.sublist(0, session.pauses.length - 1),
                session.pauses.last.close(now),
              ],
            )
          : session;
      await _repo.appendHistory(
        closed.copyWith(endedAt: now, endReason: SessionEndReason.aborted),
      );
      await _repo.clearActive();
      _serverFinalize(closed);
    }
    _cues.onAbort();
    state = FocusState.ready(
      state.phase,
      focusesBefore: state.focusesBefore,
      essentialId: state.essentialId,
      essentialTitle: state.essentialTitle,
      lastCompleted: state.lastCompleted,
      completionPulse: state.completionPulse,
    );
  }

  /// Skip a break and go straight to the next focus.
  Future<void> skipBreak() async {
    if (state.isFocus) return;
    await abort();
    final next = PomodoroCycle.next(state.phase, state.focusesBefore);
    state = FocusState.ready(
      next.phase,
      focusesBefore: next.focusesAfter,
      essentialId: state.essentialId,
      essentialTitle: state.essentialTitle,
      lastCompleted: state.lastCompleted,
      completionPulse: state.completionPulse,
    );
  }

  /// Tell the server the session is over (best-effort). The server decides
  /// validity from its own anchor; we also pass whether the user ever paused so
  /// a pause that happened offline still voids the reward on finalize.
  void _serverFinalize(FocusSession session) {
    final serverId = session.serverId;
    if (serverId == null) return;
    unawaited(
      _api.finalize(
        serverId: serverId,
        idempotencyKey: session.idempotencyKey,
        clientPaused: session.rewardVoided,
      ),
    );
  }

  void _startTicker() {
    _ticker?.cancel();
    // Disabled in unit tests so completion is driven deterministically via
    // debugTick rather than a real wall-clock timer racing the fake clock.
    if (!ref.read(focusTickerEnabledProvider)) return;
    _ticker = Timer.periodic(
      const Duration(milliseconds: 250),
      (_) => unawaited(_refresh()),
    );
  }

  void _stopTicker() {
    _ticker?.cancel();
    _ticker = null;
  }

  Future<void> _refresh() async {
    if (_finalizing) return;
    final session = state.session;
    if (session == null || !state.running) return;
    final remaining = session.remainingSeconds(_now);
    if (remaining <= 0) {
      // Guard against a second heartbeat / resume hook re-entering mid-finalize.
      _finalizing = true;
      _stopTicker();
      await _finalizeAndAdvance(session, playCues: true, endedAt: _now);
      _finalizing = false;
    } else if (remaining != state.remainingSeconds) {
      state = state.copyWith(remainingSeconds: remaining);
    }
  }

  Future<void> _finalizeAndAdvance(
    FocusSession session, {
    required bool playCues,
    required DateTime endedAt,
  }) async {
    final completedPhase = session.kind;
    await _repo.appendHistory(
      session.copyWith(endedAt: endedAt, endReason: SessionEndReason.completed),
    );
    await _repo.clearActive();
    _serverFinalize(session);

    final next = PomodoroCycle.next(completedPhase, session.focusesBefore);
    state = FocusState.ready(
      next.phase,
      focusesBefore: next.focusesAfter,
      essentialId: state.essentialId,
      essentialTitle: state.essentialTitle,
      lastCompleted: completedPhase,
      completionPulse: state.completionPulse + 1,
    );
    if (playCues) _cues.onComplete(completedPhase);
  }

  Future<void> _hydrate() async {
    // Runs once: the auto microtask and any debugHydrate cooperate via this flag.
    if (_hydrated) return;
    _hydrated = true;
    // Only restore on a pristine launch. If a session was begun before this
    // ran (the user tapped fast, or a test drove begin first), leave it alone.
    if (!state.ready) return;

    FocusSession? session;
    try {
      session = await _repo.loadActive();
    } catch (_) {
      return; // storage unavailable — start fresh, never block the app
    }
    if (session == null || !session.isActive || !state.ready) return;

    final now = _now;
    final remaining = session.remainingSeconds(now);

    if (session.isPaused) {
      state = FocusState(
        phase: session.kind,
        status: FocusStatus.paused,
        plannedSeconds: session.plannedSeconds,
        remainingSeconds: remaining,
        focusesBefore: session.focusesBefore,
        session: session,
        essentialId: session.essentialId,
        essentialTitle: session.essentialTitle,
        rewardVoided: session.rewardVoided,
      );
      return;
    }

    if (remaining <= 0) {
      // It finished while we were away: log it, advance — but stay quiet on a
      // cold launch (no chime out of nowhere).
      await _finalizeAndAdvance(session, playCues: false, endedAt: now);
      return;
    }

    state = FocusState(
      phase: session.kind,
      status: FocusStatus.running,
      plannedSeconds: session.plannedSeconds,
      remainingSeconds: remaining,
      focusesBefore: session.focusesBefore,
      session: session,
      essentialId: session.essentialId,
      essentialTitle: session.essentialTitle,
      rewardVoided: session.rewardVoided,
    );
    _startTicker();
  }

  void _onResumed() {
    if (state.running) unawaited(_refresh());
  }

  /// Test seam: drive a single recompute deterministically (no real timer).
  @visibleForTesting
  Future<void> debugTick() => _refresh();

  /// Test seam: run rehydration synchronously from a test.
  @visibleForTesting
  Future<void> debugHydrate() => _hydrate();
}

final focusEngineProvider = NotifierProvider<FocusEngine, FocusState>(
  FocusEngine.new,
);

/// Whether the engine runs its real heartbeat timer. Always true in the app;
/// overridden to false in tests, which advance a fake clock and call
/// `debugTick` so completion is deterministic.
final focusTickerEnabledProvider = Provider<bool>((ref) => true);
