#!/usr/bin/env python3
"""Deterministic pass grades for the town plate (DESIGN.md law:
dawn/midnight are palette-and-light re-grades of ONE plate, never
new paintings). Pure PIL colour maths; same input + same constants
= byte-identical output. The ops are recorded in the asset chain.

Usage: grade_plates.py <town_dusk.png> <out_dir>
Writes town_midnight.png and town_dawn.png beside the source grade.
"""
import hashlib
import json
import os
import sys

from PIL import Image, ImageEnhance


def grade(img, brightness, color, contrast, blue_shift):
    out = img.convert("RGB")
    out = ImageEnhance.Brightness(out).enhance(brightness)
    out = ImageEnhance.Color(out).enhance(color)
    out = ImageEnhance.Contrast(out).enhance(contrast)
    if blue_shift:
        r, g, b = out.split()
        b = b.point(lambda v: min(255, int(v * 1.22) + 14))
        r = r.point(lambda v: int(v * 0.72))
        out = Image.merge("RGB", (r, g, b))
    return out


def main(src, out_dir):
    img = Image.open(src)
    variants = {
        "town_midnight.png": grade(img, 0.52, 0.82, 1.06, True),
        "town_dawn.png": grade(img, 1.04, 1.02, 0.97, False),
    }
    for name, out in variants.items():
        path = os.path.join(out_dir, name)
        out.save(path)
        digest = hashlib.sha256(open(path, "rb").read()).hexdigest()
        print(json.dumps({"file": name, "sha256": digest, "bytes": os.path.getsize(path)}))


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2])
