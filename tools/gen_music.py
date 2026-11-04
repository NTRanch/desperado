#!/usr/bin/env python3
"""Desperado music generation — Aria (ACE-Step 1.5 turbo) via the
estate ComfyUI instance (port 8191, shared tonight; the queue
serialises us politely behind the asset-factory lane).

Silent by construction: files are written, never played
(AUDIO SILENCE RULE). Provenance for every track is appended to
assets/asset-records.json by tools/gen_assets.py conventions:
this script prints one JSON line per finished track.

Usage: gen_music.py <out_dir>
"""
import json
import sys
import time
import urllib.request

BASE = "http://127.0.0.1:8191"
UNET = "acestep_v1.5_turbo.safetensors"
CLIP1 = "qwen_0.6b_ace15.safetensors"
CLIP2 = "qwen_4b_ace15.safetensors"
VAE = "ace_1.5_vae.safetensors"

TRACKS = [
    {
        "stem": "dusk_theme",
        "tags": "instrumental spaghetti western score, twangy electric guitar, harmonica lead, brushed drums, warm desert dusk mood, cinematic, loopable",
        "bpm": 96, "duration": 60.0, "seed": 20261120, "keyscale": "E minor",
    },
    {
        "stem": "midnight_theme",
        "tags": "instrumental dark western ambient, sparse piano, distant harmonica, night desert wind mood, slow tension, cinematic, loopable",
        "bpm": 78, "duration": 60.0, "seed": 20261121, "keyscale": "A minor",
    },
    {
        "stem": "dawn_theme",
        "tags": "instrumental hopeful western score, acoustic guitar arpeggios, soft strings, sunrise warmth, resolved cinematic mood, loopable",
        "bpm": 92, "duration": 60.0, "seed": 20261122, "keyscale": "G major",
    },
    {
        "stem": "duel_theme",
        "tags": "instrumental tense western duel music, staccato strings, ticking percussion, muted trumpet stabs, standoff tension, cinematic, loopable",
        "bpm": 118, "duration": 45.0, "seed": 20261123, "keyscale": "D minor",
    },
    {
        "stem": "boss_theme",
        "tags": "instrumental dramatic western boss battle, driving drums, low brass, distorted guitar pulses, escalating menace, cinematic, loopable",
        "bpm": 132, "duration": 45.0, "seed": 20261124, "keyscale": "E minor",
    },
]


def post(path, payload):
    req = urllib.request.Request(
        BASE + path,
        data=json.dumps(payload).encode(),
        headers={"Content-Type": "application/json"},
    )
    with urllib.request.urlopen(req, timeout=30) as resp:
        return json.loads(resp.read())


def get(path):
    with urllib.request.urlopen(BASE + path, timeout=30) as resp:
        return json.loads(resp.read())


def workflow(track):
    return {
        "1": {"class_type": "UNETLoader", "inputs": {"unet_name": UNET, "weight_dtype": "default"}},
        "2": {"class_type": "DualCLIPLoader", "inputs": {"clip_name1": CLIP1, "clip_name2": CLIP2, "type": "ace"}},
        "3": {"class_type": "VAELoader", "inputs": {"vae_name": VAE}},
        "4": {"class_type": "TextEncodeAceStepAudio1.5", "inputs": {
            "clip": ["2", 0], "tags": track["tags"], "lyrics": "",
            "seed": track["seed"], "bpm": track["bpm"], "duration": track["duration"],
            "timesignature": "4", "language": "en", "keyscale": track["keyscale"],
            "generate_audio_codes": True, "cfg_scale": 2.0, "temperature": 0.85,
            "top_p": 0.9, "top_k": 0, "min_p": 0.0,
        }},
        "5": {"class_type": "ConditioningZeroOut", "inputs": {"conditioning": ["4", 0]}},
        "6": {"class_type": "EmptyAceStep1.5LatentAudio", "inputs": {"seconds": track["duration"], "batch_size": 1}},
        "7": {"class_type": "ModelSamplingAuraFlow", "inputs": {"model": ["1", 0], "shift": 3.0}},
        "8": {"class_type": "KSampler", "inputs": {
            "model": ["7", 0], "positive": ["4", 0], "negative": ["5", 0],
            "latent_image": ["6", 0], "seed": track["seed"], "steps": 8,
            "cfg": 1.0, "sampler_name": "euler", "scheduler": "simple", "denoise": 1.0,
        }},
        "9": {"class_type": "VAEDecodeAudio", "inputs": {"samples": ["8", 0], "vae": ["3", 0]}},
        "10": {"class_type": "SaveAudioMP3", "inputs": {
            "audio": ["9", 0], "filename_prefix": "desperado/" + track["stem"], "quality": "320k",
        }},
    }


def main(out_dir):
    for track in TRACKS:
        submitted = post("/prompt", {"prompt": workflow(track)})
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
            print(json.dumps({"stem": track["stem"], "error": "timeout"}))
            continue
        outputs = entry["outputs"]["10"]["audio"]
        item = outputs[0]
        print(json.dumps({
            "stem": track["stem"], "seed": track["seed"], "bpm": track["bpm"],
            "duration_s": track["duration"], "tags": track["tags"],
            "file": item["filename"], "subfolder": item.get("subfolder", ""),
        }))


if __name__ == "__main__":
    main(sys.argv[1] if len(sys.argv) > 1 else ".")
