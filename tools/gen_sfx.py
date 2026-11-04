#!/usr/bin/env python3
"""Desperado SFX — procedural synthesis (numpy), files only.

Every sound is synthesised from primitives (noise bursts, sine
partials, filtered thumps): no samples, no recordings, nothing
played. Output: 22050 Hz mono 16-bit WAV under the given directory.
Deterministic: one seeded RNG for the whole run.

Usage: gen_sfx.py <out_dir>
"""
import hashlib
import json
import os
import sys

import numpy as np
from scipy.signal import butter, lfilter

SR = 22050
RNG = np.random.default_rng(20261103)


def env(n, attack=0.004, decay=0.10):
    t = np.arange(n) / SR
    return np.minimum(1.0, t / max(attack, 1e-4)) * np.exp(-t / decay)


def noise_burst(dur, cutoff, gain=0.9, decay=0.08):
    n = int(dur * SR)
    x = RNG.standard_normal(n)
    b, a = butter(2, cutoff / (SR / 2), btype="low")
    x = lfilter(b, a, x)
    x = x / (np.max(np.abs(x)) + 1e-9)
    return x * env(n, decay=decay) * gain


def tone(freq, dur, gain=0.5, decay=0.15, slide_to=None, harmonics=(1.0,)):
    n = int(dur * SR)
    t = np.arange(n) / SR
    if slide_to is not None:
        f = freq * (slide_to / freq) ** (t / dur)
        phase = 2 * np.pi * np.cumsum(f) / SR
    else:
        phase = 2 * np.pi * freq * t
    x = np.zeros(n)
    for i, h in enumerate(harmonics):
        x += h * np.sin(phase * (i + 1))
    x = x / (np.max(np.abs(x)) + 1e-9)
    return x * env(n, decay=decay) * gain


def mix(*parts):
    n = max(len(p) for p in parts)
    out = np.zeros(n)
    for p in parts:
        out[: len(p)] += p
    return out


def write(name, samples, out_dir):
    samples = np.clip(samples, -1.0, 1.0)
    pcm = (samples * 32767).astype(np.int16)
    path = os.path.join(out_dir, name + ".wav")
    with open(path, "wb") as fh:
        fh.write(b"RIFF")
        fh.write((36 + len(pcm) * 2).to_bytes(4, "little"))
        fh.write(b"WAVEfmt ")
        fh.write((16).to_bytes(4, "little"))
        fh.write((1).to_bytes(2, "little"))
        fh.write((1).to_bytes(2, "little"))
        fh.write(SR.to_bytes(4, "little"))
        fh.write((SR * 2).to_bytes(4, "little"))
        fh.write((2).to_bytes(2, "little"))
        fh.write((16).to_bytes(2, "little"))
        fh.write(b"data")
        fh.write((len(pcm) * 2).to_bytes(4, "little"))
        fh.write(pcm.tobytes())
    digest = hashlib.sha256(open(path, "rb").read()).hexdigest()
    print(json.dumps({"stem": name, "sha256": digest, "bytes": os.path.getsize(path)}))


def main(out_dir):
    os.makedirs(out_dir, exist_ok=True)
    write("pistol_shot", mix(noise_burst(0.16, 2600, 0.95, 0.05), tone(140, 0.14, 0.7, 0.06, slide_to=55)), out_dir)
    write("rifle_shot", mix(noise_burst(0.30, 3400, 1.0, 0.10), tone(110, 0.26, 0.8, 0.11, slide_to=45)), out_dir)
    write("scatter_shot", mix(noise_burst(0.24, 1700, 1.0, 0.08), tone(120, 0.2, 0.7, 0.08, slide_to=50)), out_dir)
    write("enemy_shot", mix(noise_burst(0.14, 2000, 0.8, 0.05), tone(160, 0.12, 0.5, 0.05, slide_to=70)), out_dir)
    write("hit_tick", tone(2100, 0.05, 0.35, 0.03), out_dir)
    write("player_hurt", mix(tone(220, 0.18, 0.6, 0.09, slide_to=110), noise_burst(0.1, 900, 0.4, 0.05)), out_dir)
    write("parry_chime", mix(tone(1318, 0.30, 0.5, 0.16, harmonics=(1.0, 0.4)), tone(1975, 0.22, 0.3, 0.12)), out_dir)
    write("shift_snap", mix(tone(180, 0.16, 0.85, 0.07, slide_to=70), noise_burst(0.2, 1200, 0.5, 0.09)), out_dir)
    write("shift_denied", tone(196, 0.12, 0.4, 0.06), out_dir)
    write("dodge_whoosh", noise_burst(0.22, 750, 0.55, 0.10), out_dir)
    write("enemy_windup", tone(520, 0.20, 0.30, 0.14, slide_to=880), out_dir)
    write("cache_chime", mix(tone(1046, 0.4, 0.45, 0.22), tone(1568, 0.34, 0.32, 0.18), tone(2093, 0.26, 0.2, 0.13)), out_dir)
    write("ui_click", tone(880, 0.045, 0.3, 0.02), out_dir)
    write("door_open", mix(noise_burst(0.3, 500, 0.5, 0.14), tone(90, 0.3, 0.4, 0.14, slide_to=60)), out_dir)
    write("duel_start", mix(tone(392, 0.35, 0.5, 0.2), tone(587, 0.3, 0.4, 0.17)), out_dir)
    write("duel_won", mix(tone(523, 0.4, 0.5, 0.24), tone(659, 0.38, 0.45, 0.22), tone(784, 0.36, 0.4, 0.2)), out_dir)
    write("phase_shift", mix(tone(147, 0.5, 0.7, 0.26, slide_to=98), noise_burst(0.4, 900, 0.4, 0.2)), out_dir)
    write("player_down", tone(330, 0.6, 0.6, 0.3, slide_to=82), out_dir)


if __name__ == "__main__":
    main(sys.argv[1])
