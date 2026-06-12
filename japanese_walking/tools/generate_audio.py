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


def bell(freq, dur, vol=0.5):
    """Soft chime: fundamental + overtones with a long, gentle decay."""
    return mix(
        tone(freq, dur, vol, attack=0.012, decay=dur),
        tone(freq * 2, dur, vol * 0.35, attack=0.012, decay=dur),
        tone(freq * 3, dur, vol * 0.12, attack=0.012, decay=dur),
    )


def chime(notes, vol=0.5):
    """Overlapping bells: each next note starts at 55% of the previous one."""
    out = []
    for f, d in notes:
        b = bell(f, d, vol)
        start = max(0, len(out) - int(SR * d * 0.45)) if out else 0
        # extend buffer and mix
        need = start + len(b)
        out += [0.0] * max(0, need - len(out))
        for i, s in enumerate(b):
            out[start + i] += s
    return out


# Metronome: ONE crisp tick per step (single pitch, sharp envelope)
save("tick.wav", tone(1700, 0.035, vol=0.75, attack=0.001, decay=0.03))
save("tock.wav", tone(1700, 0.035, vol=0.75, attack=0.001, decay=0.03))

# Countdown blip (3-2-1 before each phase change)
save("count.wav", tone(1320, 0.07, vol=0.55, decay=0.06))

# Phase -> FAST: rising fifth, soft bells ("up we go")
save("phase_fast.wav", chime([(523, 0.5), (784, 0.9)]))

# Phase -> SLOW: falling fifth ("settle down")
save("phase_slow.wav", chime([(784, 0.5), (523, 1.0)]))

# Finish: gentle C–E–G chime
save("finish.wav", chime([(523, 0.4), (659, 0.4), (784, 1.2)]))

# Coach: out-of-zone hints (rising = speed up, falling = slow down)
save("coach_up.wav", chime([(659, 0.3), (880, 0.6)], vol=0.55))
save("coach_down.wav", chime([(880, 0.3), (587, 0.7)], vol=0.55))
