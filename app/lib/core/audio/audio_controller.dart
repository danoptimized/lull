import 'dart:async';

import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A selectable ambient bed for focus sessions. v1 ships one curated-later
/// placeholder; new entries only need a bundled asset path.
enum Soundscape {
  none('none', null),
  rain('rain', 'assets/audio/ambient_rain.wav');

  const Soundscape(this.label, this.asset);

  final String label;
  final String? asset;
}

/// One-shot cues.
enum Sfx {
  begin('assets/audio/tick_begin.wav'),
  focusComplete('assets/audio/chime_complete.wav'),
  breakComplete('assets/audio/chime_break.wav');

  const Sfx(this.asset);

  final String asset;
}

@immutable
class AudioSettings {
  const AudioSettings({
    this.soundscape = Soundscape.rain,
    this.sfxEnabled = true,
    this.ambientActive = false,
  });

  final Soundscape soundscape;
  final bool sfxEnabled;

  /// Whether an ambient bed is meant to be playing right now (a focus is
  /// running). Lets pause/resume restore the prior intent.
  final bool ambientActive;

  AudioSettings copyWith({
    Soundscape? soundscape,
    bool? sfxEnabled,
    bool? ambientActive,
  }) => AudioSettings(
    soundscape: soundscape ?? this.soundscape,
    sfxEnabled: sfxEnabled ?? this.sfxEnabled,
    ambientActive: ambientActive ?? this.ambientActive,
  );

  @override
  bool operator ==(Object other) =>
      other is AudioSettings &&
      other.soundscape == soundscape &&
      other.sfxEnabled == sfxEnabled &&
      other.ambientActive == ambientActive;

  @override
  int get hashCode => Object.hash(soundscape, sfxEnabled, ambientActive);
}

/// Owns the two `just_audio` players (a looping ambient bed and a one-shot SFX
/// player) and the user's audio preferences.
///
/// Every playback call is wrapped: missing assets, denied web autoplay, or an
/// absent plugin degrade to silence rather than throwing into the timer engine.
class AudioController extends Notifier<AudioSettings> {
  static const String _kSoundscape = 'lull.audio.soundscape.v1';
  static const String _kSfx = 'lull.audio.sfx_enabled.v1';

  AudioPlayer? _ambient;
  AudioPlayer? _sfx;
  bool _sessionConfigured = false;

  @override
  AudioSettings build() {
    ref.onDispose(() {
      _ambient?.dispose();
      _sfx?.dispose();
    });
    unawaited(_restore());
    return const AudioSettings();
  }

  /// Load saved prefs after the synchronous default (a brief default→saved
  /// settle is fine — nothing is playing at startup). Never throws.
  Future<void> _restore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final name = prefs.getString(_kSoundscape);
      final match = Soundscape.values.where((s) => s.name == name);
      state = state.copyWith(
        soundscape: match.isEmpty ? state.soundscape : match.first,
        sfxEnabled: prefs.getBool(_kSfx) ?? state.sfxEnabled,
      );
    } catch (_) {
      // No prefs plugin (tests without mock values) — keep defaults.
    }
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kSoundscape, state.soundscape.name);
      await prefs.setBool(_kSfx, state.sfxEnabled);
    } catch (_) {}
  }

  Future<void> _ensureSession() async {
    if (_sessionConfigured) return;
    _sessionConfigured = true;
    try {
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration.music());
    } catch (_) {
      // No audio session on this platform (e.g. web) — fine.
    }
  }

  Future<void> setSoundscape(Soundscape soundscape) async {
    state = state.copyWith(soundscape: soundscape);
    unawaited(_persist());
    if (!state.ambientActive) return;
    if (soundscape == Soundscape.none) {
      await _stopAmbient();
    } else {
      await _startAmbient();
    }
  }

  void setSfxEnabled(bool enabled) {
    state = state.copyWith(sfxEnabled: enabled);
    unawaited(_persist());
  }

  /// Begin the selected ambient bed (called when a focus starts).
  Future<void> startAmbient() async {
    state = state.copyWith(ambientActive: true);
    await _startAmbient();
  }

  Future<void> pauseAmbient() async {
    try {
      await _ambient?.pause();
    } catch (_) {}
  }

  Future<void> resumeAmbient() async {
    if (!state.ambientActive || state.soundscape == Soundscape.none) return;
    try {
      await _ambient?.play();
    } catch (_) {}
  }

  Future<void> stopAmbient() async {
    state = state.copyWith(ambientActive: false);
    await _stopAmbient();
  }

  Future<void> playSfx(Sfx sfx) async {
    if (!state.sfxEnabled) return;
    await _ensureSession();
    try {
      final player = _sfx ??= AudioPlayer();
      await player.setAsset(sfx.asset);
      await player.setVolume(0.7);
      await player.play();
    } catch (_) {}
  }

  Future<void> _startAmbient() async {
    final asset = state.soundscape.asset;
    if (asset == null) return;
    await _ensureSession();
    try {
      final player = _ambient ??= AudioPlayer();
      await player.setAsset(asset);
      await player.setLoopMode(LoopMode.all);
      await player.setVolume(0.5);
      await player.play();
    } catch (_) {}
  }

  Future<void> _stopAmbient() async {
    try {
      await _ambient?.stop();
    } catch (_) {}
  }
}

final audioControllerProvider =
    NotifierProvider<AudioController, AudioSettings>(AudioController.new);
