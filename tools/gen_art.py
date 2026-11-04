#!/usr/bin/env python3
"""Desperado still art — Iris (Illustrious-XL-v1.1) via the estate
ComfyUI instance (port 8191). Production recipe of record from the
Keeper Lessons characters pack: euler_ancestral / normal, 30 steps,
CFG 6.0. Prompts follow the environments pack wording laws: name
structures concretely, tokenise plurality, one warm accent family,
no text anywhere (art bible law 4).

Prints one JSON provenance line per asset. Files land in the
instance output dir; the caller moves them into the project.

Usage: gen_art.py
"""
import json
import time
import urllib.request

BASE = "http://127.0.0.1:8191"
CKPT = "Illustrious-XL-v1.1.safetensors"
NEG = ("text, letters, words, signage, watermark, signature, modern, "
       "photorealistic, car, antenna, radio mast, satellite dish, "
       "blurry, deformed hands, extra fingers, crowd")

ASSETS = [
    {
        "stem": "town_dusk", "w": 1216, "h": 704, "seed": 20261110,
        "pos": ("stylized 2D game background plate, orbital desert frontier "
                "town plaza at dusk, adobe stone building frontage on both "
                "sides, a row of market stalls with canvas awnings, a lane "
                "of lamp-posts with warm amber light, stone beacon turret "
                "water tower, gunsmith workshop with a wide wooden door, "
                "saloon with a porch, dusty rose and amber sunset sky, "
                "layered depth, empty plaza foreground, painterly, "
                "no people, one warm accent family of lamp light"),
    },
    {
        "stem": "heir", "w": 832, "h": 1024, "seed": 20261111,
        "pos": ("portrait bust of a young man gunfighter gunsmith, long "
                "dark brown coat, tousled black hair, warm brown skin, "
                "amber-brown eyes, determined expression, a shape-shifting "
                "magic-tech pistol at his hip, desert dusk rim light, "
                "stylized painterly game portrait, plain dark background"),
    },
    {
        "stem": "enforcer", "w": 832, "h": 1024, "seed": 20261112,
        "pos": ("portrait bust of a stern woman corporate enforcer, short "
                "crimson hair, tan skin, grey eyes, dark armored coat with "
                "one steel pauldron, scar through one eyebrow, stylized "
                "painterly game portrait, plain dark background"),
    },
    {
        "stem": "witness", "w": 832, "h": 1024, "seed": 20261113,
        "pos": ("portrait bust of a nervous young woman clerk, brown hair "
                "in a single braid, light warm skin, green eyes, plain "
                "work dress with a ledger under one arm, anxious "
                "expression, stylized painterly game portrait, plain "
                "dark background"),
    },
    {
        "stem": "captain", "w": 832, "h": 1024, "seed": 20261114,
        "pos": ("portrait bust of an older man military captain, "
                "silver-grey hair, weathered brown skin, dark violet-grey "
                "long coat with a magenta sash, scarred jaw, cold "
                "expression, stylized painterly game portrait, plain "
                "dark background"),
    },
    {
        "stem": "agent", "w": 832, "h": 1024, "seed": 20261115,
        "pos": ("portrait bust of a cold elegant man in a black suit "
                "coat, slicked black hair, pale skin, dark eyes, pale "
                "gold necktie, calm sinister smile, stylized painterly "
                "game portrait, plain dark background"),
    },
    {
        "stem": "mother", "w": 832, "h": 1024, "seed": 20261116,
        "pos": ("portrait bust of a warm middle-aged woman master "
                "gunsmith, dark brown hair with grey streaks in a bun, "
                "warm brown skin, kind strong expression, work apron "
                "over a dress, workshop glow behind her, stylized "
                "painterly game portrait, plain dark background"),
    },
]


def post(path, payload):
    req = urllib.request.Request(
        BASE + path, data=json.dumps(payload).encode(),
        headers={"Content-Type": "application/json"})
    with urllib.request.urlopen(req, timeout=30) as resp:
        return json.loads(resp.read())


def get(path):
    with urllib.request.urlopen(BASE + path, timeout=30) as resp:
        return json.loads(resp.read())


def workflow(asset):
    return {
        "1": {"class_type": "CheckpointLoaderSimple", "inputs": {"ckpt_name": CKPT}},
        "2": {"class_type": "CLIPTextEncode", "inputs": {"clip": ["1", 1], "text": asset["pos"]}},
        "3": {"class_type": "CLIPTextEncode", "inputs": {"clip": ["1", 1], "text": NEG}},
        "4": {"class_type": "EmptyLatentImage", "inputs": {"width": asset["w"], "height": asset["h"], "batch_size": 1}},
        "5": {"class_type": "KSampler", "inputs": {
            "model": ["1", 0], "positive": ["2", 0], "negative": ["3", 0],
            "latent_image": ["4", 0], "seed": asset["seed"], "steps": 30,
            "cfg": 6.0, "sampler_name": "euler_ancestral", "scheduler": "normal",
            "denoise": 1.0}},
        "6": {"class_type": "VAEDecode", "inputs": {"samples": ["5", 0], "vae": ["1", 2]}},
        "7": {"class_type": "SaveImage", "inputs": {"images": ["6", 0], "filename_prefix": "desperado/" + asset["stem"]}},
    }


def main():
    for asset in ASSETS:
        submitted = post("/prompt", {"prompt": workflow(asset)})
        prompt_id = submitted["prompt_id"]
        deadline = time.time() + 900
        entry = None
        while time.time() < deadline:
            history = get("/history/" + prompt_id)
            if prompt_id in history:
                entry = history[prompt_id]
                break
            time.sleep(5)
        if entry is None:
            print(json.dumps({"stem": asset["stem"], "error": "timeout"}))
            continue
        item = entry["outputs"]["7"]["images"][0]
        print(json.dumps({
            "stem": asset["stem"], "seed": asset["seed"],
            "prompt": asset["pos"], "file": item["filename"],
            "subfolder": item.get("subfolder", ""),
        }))


if __name__ == "__main__":
    main()
