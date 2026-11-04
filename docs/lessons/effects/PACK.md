---
pack: sfw/effects
version: 1.0.0
lane: sfw
class: effects (effect timelines — emitted data)
status: ACTIVE lesson card — exemplars are gate-verified DATA artifacts
consumers:
  Sylvia/Clara: timeline authoring in lumen-fx/1
  (the pipe evaluator + flash gate are the authority; a timeline that
  fails the gate does not ship, whatever its author intended)
changelog:
  1.0.0 2026-11-03 — from SFW pipes Stage 2 (D-863): the lumen-fx/1
    format + its two worked effects.
---

# SFW Effects — timelines are data, and the flash gate is law

## The SHOULD-BE-SEEN standard

An effect is an `lumen-fx/1` timeline record: emitters, keys, and a
seeded evolution, evaluated deterministically by the pipe's
integer-only evaluator. Two hard laws:

1. **Photosafety is a gate, not a taste.** Every timeline passes the
   flash-rate gate: sampled luminance flashes ≤ 3 per second
   (Versemend precedent; the OE-1b discipline, D-785 — slower,
   feathered transitions for epilepsy safety — is the design posture
   behind the number). A 5 Hz strobe authored against this class
   measured 4.5 flashes/s and was REFUSED. There is no waiver path
   in the format.
2. **Replay must be identical.** The evaluator emits a replay hash;
   two evaluations of one record must agree bit-for-bit
   (`hash_agreement: true` in both worked records). An effect that
   cannot replay identically is not an asset, it is a screenshot of
   an accident.

Effects are EMIT-format in the D-866 matrix: the record is the
asset; renderers consume it. Models author timelines as structured
data (Sylvia/Clara); no raster effect plates are generated in this
lane's pipes.

## Exemplars (data artifacts, gate-verified)

| Artifact | Gate evidence | What it teaches |
|---|---|---|
| Versemend seal-glow — `~/workspace/content-factory-20261103/sfw/evidence/stage2/fx-seal-glow.json` | `fx_verified: true`, replay hash `62645b8b…fa85` identical across runs, flash rate **0.250/s** vs cap 3.0 | The correspondence proof: this record re-expresses the shipped slice's own seal-glow effect and measures EXACTLY the flash rate the game's shipped selftest reads (0.250/s) — the format describes reality, not an approximation of it. |
| Niflheim ember-drift — `~/workspace/content-factory-20261103/sfw/evidence/stage2/fx-ember-drift.json` | `fx_verified: true`, replay hash `4268b50b…1229` identical, flash rate 0.0/s | The ambient class: drifting particulate with zero flash content — the default register for stratum ambience. |

## Failure museum

| Defect class | Evidence | The lesson |
|---|---|---|
| **Strobe authored as ambience**: a 5 Hz pulse submitted in the ambient register | Stage 2 adversarial case: measured 4.5 flashes/s, refused at the gate | Authoring intent does not soften measurement. If a design wants pulse, it authors *slow* pulse (the NSFW lane's hypno-pulse breathes at a fraction of the cap) or it does not ship. |

## Canon constraints as data

- Format: `lumen-fx/1` (in-tree format doc `docs/pipes/FX-FORMAT.md`
  on the SFW pipes branch). Convergence with the NTRanch lane's
  `effect-timeline/1` is a named open item (PIPES.md §10) — the two
  formats share the spine (seeded, fixed-step, replay-hashed,
  flash-gated); a pipe run records which format it emitted.
- Fixed-step evaluation at 60 steps/s; per-emitter seeded streams;
  particle digests quantized before hashing (the fxline precedent).

## OPST topic descriptors

- `descriptor-effect-timeline.txt` — for Sylvia/Clara: authoring
  brief (declare flash budget first; emitters as data; replay-hash
  agreement is part of done).
