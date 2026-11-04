#!/usr/bin/env python3
"""Writes assets/ASSET-RECORDS.json — the D-865 provenance record
for every generated or synthesised asset in the slice.

Describe -> Propose -> Freeze -> Emit -> Prove: the prompts and
tags below are the frozen Propose artifacts (copied verbatim from
the generation run logs), Emit is the named model + seed, Prove is
the file's own SHA-256 plus a frozen record hash. Every asset is
born `candidate`; keeper status is the Owner's eye only.

Usage: build_records.py <genart_log> <genmusic_log>
Run from the project root.
"""
import hashlib
import json
import os
import sys

IRIS_SHA = "536863e9f0c13b0ce834e2f8a19ada425ee4f722c0ad3d0051ec7e6adaa8156c"
ACE_SHA = "3f6e0797fad420a39bd33979eb6e840e30989e34a3794e843d23b60ec6e422d7"
RUN = "desperado-build-20261103"


def sha256(path):
    return hashlib.sha256(open(path, "rb").read()).hexdigest()


def freeze(record):
    blob = json.dumps(record, sort_keys=True).encode()
    record["record_hash"] = hashlib.sha256(blob).hexdigest()
    return record


def main(genart_log, genmusic_log):
    records = []
    for line in open(genart_log):
        line = line.strip()
        if not line.startswith("{"):
            continue
        item = json.loads(line)
        stem = item["stem"]
        kind = "plate" if stem.startswith("town") else "portrait"
        path = "assets/plates/%s.png" % stem if kind == "plate" else "assets/portraits/%s.png" % stem
        records.append(freeze({
            "asset": path, "kind": kind, "status": "candidate",
            "made_by": {"name": "Iris", "category": "Image",
                        "model": "Illustrious-XL-v1.1",
                        "weights": "Illustrious-XL-v1.1.safetensors",
                        "weights_sha256": IRIS_SHA},
            "seed": item["seed"], "prompt": item["prompt"],
            "recipe": "euler_ancestral/normal, 30 steps, CFG 6.0",
            "run": RUN, "sha256": sha256(path),
        }))
    for name, brightness in (("town_midnight", "0.52/blue-shift"), ("town_dawn", "1.04")):
        path = "assets/plates/%s.png" % name
        records.append(freeze({
            "asset": path, "kind": "plate-grade", "status": "candidate",
            "made_by": {"name": "deterministic finish op", "category": "Image",
                        "model": "tools/grade_plates.py (PIL)",
                        "weights": "n/a", "weights_sha256": "n/a"},
            "seed": None, "prompt": "grade of assets/plates/town_dusk.png, brightness %s" % brightness,
            "recipe": "DESIGN.md re-grade law: one plate, palette grades per pass",
            "run": RUN, "sha256": sha256(path),
        }))
    for line in open(genmusic_log):
        line = line.strip()
        if not line.startswith("{"):
            continue
        item = json.loads(line)
        path = "assets/audio/music/%s.mp3" % item["stem"]
        records.append(freeze({
            "asset": path, "kind": "music", "status": "candidate",
            "made_by": {"name": "Aria", "category": "Audio",
                        "model": "ACE-Step 1.5 turbo",
                        "weights": "acestep_v1.5_turbo.safetensors",
                        "weights_sha256": ACE_SHA},
            "seed": item["seed"], "prompt": item["tags"],
            "recipe": "blueprint recipe: 8 steps, CFG 1, euler/simple, AuraFlow shift 3, %ss @ %s BPM" % (item["duration_s"], item["bpm"]),
            "run": RUN, "sha256": sha256(path),
        }))
    sfx_dir = "assets/audio/sfx"
    for name in sorted(os.listdir(sfx_dir)):
        if not name.endswith(".wav"):
            continue
        path = os.path.join(sfx_dir, name)
        records.append(freeze({
            "asset": path, "kind": "sfx", "status": "candidate",
            "made_by": {"name": "procedural synthesis", "category": "Audio",
                        "model": "tools/gen_sfx.py (numpy, seeded RNG 20261103)",
                        "weights": "n/a", "weights_sha256": "n/a"},
            "seed": 20261103, "prompt": "synthesised from primitives; no samples",
            "recipe": "22050 Hz mono 16-bit WAV",
            "run": RUN, "sha256": sha256(path),
        }))
    out = {"game": "desperado", "run": RUN, "assets": records}
    with open("assets/ASSET-RECORDS.json", "w") as fh:
        json.dump(out, fh, indent=1)
    print("records:", len(records))


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2])
