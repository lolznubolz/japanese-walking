#!/usr/bin/env python3
"""Generates the app's sound assets into assets/audio/.

Run once from the project root (no dependencies, pure stdlib):

    python3 tools/generate_audio.py
"""
import math
import os
import struct
import wave

SR = 44100
OUT = os.path.join(os.path.dirname(__file__), "..", "assets", "audio")


def save(name, samples):
    os.makedirs(OUT, exist_ok=True)
    with wave.open(os.path.join(OUT, name), "w") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(
            b"".join(
                struct.pack("<h", max(-32767, min(32767, int(s * 32767))))
                for s in samples
            )
        )
    print("wrote", name)


def tone(freq, dur, vol=0.8, attack=0.002, decay=None):
    n = int(SR * dur)
    decay = decay or dur
    out = []
    for i in range(n):
        t = i / SR
        env = min(1, t / attack) * math.exp(-t / (decay / 5))
        out.append(vol * env * math.sin(2 * math.pi * freq * t))
    return out


def mix(*parts):
    n = max(len(p) for p in parts)
    return [sum(p[i] if i < len(p) else 0 for p in parts) for i in range(n)]


def concat(*parts):
    out = []
    for p in parts:
        out += p
    return out


def silence(dur):
    return [0.0] * int(SR * dur)


# Metronome ticks: short woodblock-like clicks, two pitches (left/right foot)
save("tick.wav", tone(1800, 0.05, vol=0.7, decay=0.04))
save("tock.wav", tone(1400, 0.05, vol=0.6, decay=0.04))

# Phase -> FAST: rising three-note motif (energetic)
save(
    "phase_fast.wav",
    concat(
        tone(660, 0.14, 0.7), silence(0.04),
        tone(880, 0.14, 0.7), silence(0.04),
        tone(1320, 0.3, 0.8, decay=0.25),
    ),
)

# Phase -> SLOW: falling two-note motif (calming)
save(
    "phase_slow.wav",
    concat(tone(880, 0.2, 0.7), silence(0.06), tone(587, 0.45, 0.7, decay=0.4)),
)

# Finish: small fanfare (C–E–G–C arpeggio)
save(
    "finish.wav",
    concat(
        tone(523, 0.16, 0.7),
        tone(659, 0.16, 0.7),
        tone(784, 0.16, 0.7),
        mix(tone(1046, 0.6, 0.6, decay=0.5), tone(523, 0.6, 0.3, decay=0.5)),
    ),
)
