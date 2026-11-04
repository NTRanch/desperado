#!/usr/bin/env python3
"""Flash gate for Desperado effect records (lumen-fx/1 discipline).

Samples a record's luminance envelope at 120 Hz under the worst
case the runtime contract allows (the pulse repeated every
min_repeat_s, sustained), and counts flashes: a flash is a
luminance rise of >= 0.10 above the running trough followed by a
fall of >= 0.10 from the running peak. Gate: <= 3.0 flashes/s
(the estate cap; Versemend precedent, D-785 posture).

Usage: flash_gate.py <record.json> [<record.json> ...]
Exit 0 = every record inside the gate; 1 = a refusal.
"""
import json
import sys

SAMPLE_HZ = 120.0
CAP_PER_S = 3.0
RISE = 0.10


def envelope_value(keys, t):
    if t <= keys[0]["t_s"]:
        return keys[0]["luminance"]
    for a, b in zip(keys, keys[1:]):
        if a["t_s"] <= t <= b["t_s"]:
            span = b["t_s"] - a["t_s"]
            if span <= 0:
                return b["luminance"]
            f = (t - a["t_s"]) / span
            return a["luminance"] + f * (b["luminance"] - a["luminance"])
    return keys[-1]["luminance"]


def flashes_per_second(record):
    env = record["luminance_envelope"]
    keys = env["keys"]
    pulse_s = env["pulse_s"]
    repeat_s = record["runtime_contract"]["min_repeat_s"]
    baseline = env["baseline"]
    duration = max(10.0, repeat_s * 12)
    steps = int(duration * SAMPLE_HZ)
    flashes = 0
    trough = peak = baseline
    armed = True
    for i in range(steps):
        t = i / SAMPLE_HZ
        phase = t % repeat_s
        lum = envelope_value(keys, phase) if phase <= pulse_s else baseline
        trough = min(trough, lum)
        peak = max(peak, lum)
        if armed and lum - trough >= RISE:
            flashes += 1
            armed = False
            peak = lum
        if not armed and peak - lum >= RISE:
            armed = True
            trough = lum
    return flashes / duration


def main(paths):
    ok = True
    for path in paths:
        with open(path) as fh:
            record = json.load(fh)
        rate = flashes_per_second(record)
        verdict = "PASS" if rate <= CAP_PER_S else "FAIL"
        if rate > CAP_PER_S:
            ok = False
        print(f"{verdict} {record['id']}: {rate:.3f} flashes/s (cap {CAP_PER_S}/s)")
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
