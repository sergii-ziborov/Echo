#!/usr/bin/env python3
"""Generate short UI wavs for ECHO. No third-party deps."""
from __future__ import annotations
import math
import struct
import wave
from pathlib import Path

RATE = 44100
OUT = Path(__file__).resolve().parents[1] / "Echo" / "Resources" / "Sounds"


def write_wav(name: str, samples: list[float]) -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    path = OUT / f"{name}.wav"
    with wave.open(str(path), "w") as wf:
        wf.setnchannels(1)
        wf.setsampwidth(2)
        wf.setframerate(RATE)
        frames = b"".join(struct.pack("<h", max(-32767, min(32767, int(s * 32767)))) for s in samples)
        wf.writeframes(frames)


def env(i: int, n: int, attack: float = 0.01, release: float = 0.08) -> float:
    t = i / RATE
    dur = n / RATE
    a = min(1.0, t / attack) if attack > 0 else 1.0
    r = min(1.0, max(0.0, (dur - t) / release)) if release > 0 else 1.0
    return a * r


def tone(freq: float, dur: float, amp: float = 0.35, attack: float = 0.01, release: float = 0.08) -> list[float]:
    n = int(dur * RATE)
    return [amp * env(i, n, attack, release) * math.sin(2 * math.pi * freq * i / RATE) for i in range(n)]


def mix(*parts: list[float]) -> list[float]:
    n = max(len(p) for p in parts)
    out = [0.0] * n
    for p in parts:
        for i, s in enumerate(p):
            out[i] += s
    peak = max(1e-6, max(abs(s) for s in out))
    if peak > 0.95:
        out = [s * 0.95 / peak for s in out]
    return out


def main() -> None:
    write_wav("tap", tone(880, 0.07, 0.22, 0.002, 0.05))
    write_wav("collect", mix(tone(660, 0.12, 0.28), [0] * int(0.04 * RATE) + tone(990, 0.14, 0.26)))
    write_wav("warn", mix(tone(220, 0.22, 0.22), tone(330, 0.22, 0.12)))
    whoosh = []
    n = int(0.28 * RATE)
    for i in range(n):
        t = i / RATE
        noise = ((i * 1103515245 + 12345) % 32768) / 32768 - 0.5
        whoosh.append(0.22 * env(i, n, 0.01, 0.12) * noise * (1 + math.sin(2 * math.pi * (180 + t * 420) * t)))
    write_wav("spawn", whoosh)
    death = mix(tone(196, 0.35, 0.3, 0.005, 0.25), tone(147, 0.4, 0.22, 0.005, 0.3))
    write_wav("death", death)
    win = mix(
        tone(523.25, 0.18, 0.22),
        [0] * int(0.12 * RATE) + tone(659.25, 0.18, 0.22),
        [0] * int(0.24 * RATE) + tone(783.99, 0.28, 0.26, 0.01, 0.18),
    )
    write_wav("win", win)
    print(f"wrote sounds to {OUT}")


if __name__ == "__main__":
    main()
