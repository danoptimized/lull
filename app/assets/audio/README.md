# Audio assets

These four `.wav` files are **procedurally generated placeholders** so the audio
layer is real, wired, and demoable in M1:

- `tick_begin.wav` — a soft low cue when a session begins
- `chime_complete.wav` — a gentle two-note resolve when a focus completes
- `chime_break.wav` — a softer settle when a break completes
- `ambient_rain.wav` — a seamless ~15s gentle-rain loop (the "rain" soundscape)

Regenerate with: `python3 tooling/generate_placeholder_audio.py`

Curated, designed sound and a richer set of soundscapes replace these in the
dedicated design/content session. The `Soundscape` and `Sfx` enums in
`lib/core/audio/audio_controller.dart` are the only place to wire new files in.
