#!/usr/bin/env python3
"""Generate Lull's *placeholder* audio assets procedurally.

These are intentionally gentle, low-amplitude stand-ins so the audio layer is
real and demoable in M1. Curated, designed sound (and richer soundscapes)
replace them in the content/design session — see assets/audio/README.md.

Run:  python3 tooling/generate_placeholder_audio.py
Out:  app/assets/audio/{tick_begin,chime_complete,chime_break,ambient_rain}.wav
"""

import math
import os
import struct
import wave

import numpy as np

SR = 22050  # mono, 16-bit — small files, plenty for soft cues
OUT = os.path.join(os.path.dirname(__file__), "..", "app", "assets", "audio")


def _write(name: str, samples: np.ndarray) -> None:
    samples = np.clip(samples, -1.0, 1.0)
    pcm = (samples * 32767.0).astype("<i2")
    path = os.path.join(OUT, name)
    with wave.open(path, "w") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(pcm.tobytes())
    print(f"wrote {name}: {len(samples) / SR:.2f}s, {os.path.getsize(path) // 1024}KB")


def _t(seconds: float) -> np.ndarray:
    return np.linspace(0, seconds, int(SR * seconds), endpoint=False)


def _soft_attack(sig: np.ndarray, ms: float = 5.0) -> np.ndarray:
    n = int(SR * ms / 1000)
    if n > 0 and n < len(sig):
        ramp = np.linspace(0, 1, n) ** 2
        sig = sig.copy()
        sig[:n] *= ramp
    return sig


def glass_note(freq: float, dur: float, tau: float, amp: float) -> np.ndarray:
    """An additive, sine-based glassy/marimba tone — calm, not metallic."""
    t = _t(dur)
    partials = [(1.0, 1.0), (2.0, 0.32), (3.0, 0.12), (4.2, 0.05)]
    sig = np.zeros_like(t)
    for mult, level in partials:
        sig += level * np.sin(2 * math.pi * freq * mult * t)
    sig *= np.exp(-t / tau)
    sig = _soft_attack(sig, 6.0)
    return amp * sig / np.max(np.abs(sig) + 1e-9)


def tick_begin() -> np.ndarray:
    """A soft, low 'tuk' to mark the start of a session."""
    note = glass_note(168.0, 0.16, tau=0.045, amp=0.16)
    return note


def chime(f1: float, f2: float) -> np.ndarray:
    """Two ascending glass notes that resolve — used for completion."""
    a = glass_note(f1, 1.7, tau=0.55, amp=0.22)
    b = glass_note(f2, 1.7, tau=0.6, amp=0.18)
    out = np.zeros(int(SR * 1.9))
    out[: len(a)] += a
    off = int(SR * 0.16)
    out[off : off + len(b)] += b
    return 0.9 * out / np.max(np.abs(out) + 1e-9) * 0.5


def ambient_rain(dur: float = 16.0) -> np.ndarray:
    """Gentle rain: softened broadband noise + faint patter, seamless loop."""
    rng = np.random.default_rng(7)
    n = int(SR * dur)
    noise = rng.standard_normal(n + SR)  # extra tail for the crossfade

    # One-pole low-pass for the soft 'wash'.
    a = 0.06
    lp = np.zeros_like(noise)
    acc = 0.0
    for i in range(len(noise)):
        acc = acc + a * (noise[i] - acc)
        lp[i] = acc
    wash = lp / (np.std(lp) + 1e-9)

    # Faint high-passed 'patter' (noise minus its low-pass), kept subtle.
    patter = (noise - lp)
    patter = patter / (np.std(patter) + 1e-9)

    sig = 0.85 * wash + 0.18 * patter

    # Slow organic amplitude drift.
    td = _t(len(sig) / SR)
    drift = 1.0 + 0.12 * np.sin(2 * math.pi * 0.05 * td)
    sig = sig * drift

    sig = sig[:n]  # back to exact length
    # Seamless loop: crossfade the final 0.6s into the first 0.6s.
    xf = int(SR * 0.6)
    fade = np.linspace(0, 1, xf)
    head = sig[:xf].copy()
    tail = sig[-xf:].copy()
    sig[:xf] = head * fade + tail * (1 - fade)
    sig = sig[:-xf]

    sig = sig / (np.max(np.abs(sig)) + 1e-9)
    return 0.34 * sig  # quiet by default; the app mixes it lower still


if __name__ == "__main__":
    os.makedirs(OUT, exist_ok=True)
    _write("tick_begin.wav", tick_begin())
    _write("chime_complete.wav", chime(523.25, 783.99))   # C5 -> G5, resolves up
    _write("chime_break.wav", chime(659.25, 523.25))      # E5 -> C5, settles down
    _write("ambient_rain.wav", ambient_rain())
