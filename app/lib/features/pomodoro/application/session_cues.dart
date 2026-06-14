import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lull/core/audio/audio_controller.dart';
import 'package:lull/core/feedback/haptics.dart';
import 'package:lull/features/pomodoro/domain/focus_phase.dart';

/// Sensory feedback for session transitions, kept behind an interface so the
/// engine emits *semantic* events ("a focus completed") and never touches
/// audio or haptics directly. Tests override the provider with [NoopSessionCues].
abstract class SessionCues {
  void onBegin(FocusPhase phase);
  void onPause();
  void onResume();
  void onComplete(FocusPhase completedPhase);
  void onAbort();
}

class DefaultSessionCues implements SessionCues {
  DefaultSessionCues(this._ref);

  final Ref _ref;

  AudioController get _audio => _ref.read(audioControllerProvider.notifier);
  Haptics get _haptics => _ref.read(hapticsProvider);

  @override
  void onBegin(FocusPhase phase) {
    _haptics.light();
    unawaited(_audio.playSfx(Sfx.begin));
    if (phase == FocusPhase.focus) {
      unawaited(_audio.startAmbient());
    }
  }

  @override
  void onPause() {
    _haptics.selection();
    unawaited(_audio.pauseAmbient());
  }

  @override
  void onResume() {
    _haptics.selection();
    unawaited(_audio.resumeAmbient());
  }

  @override
  void onComplete(FocusPhase completedPhase) {
    _haptics.success();
    unawaited(_audio.stopAmbient());
    unawaited(
      _audio.playSfx(
        completedPhase == FocusPhase.focus
            ? Sfx.focusComplete
            : Sfx.breakComplete,
      ),
    );
  }

  @override
  void onAbort() {
    unawaited(_audio.stopAmbient());
  }
}

class NoopSessionCues implements SessionCues {
  const NoopSessionCues();

  @override
  void onBegin(FocusPhase phase) {}

  @override
  void onPause() {}

  @override
  void onResume() {}

  @override
  void onComplete(FocusPhase completedPhase) {}

  @override
  void onAbort() {}
}

final sessionCuesProvider = Provider<SessionCues>(DefaultSessionCues.new);
