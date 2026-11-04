---
pack: sfw/enemies
version: 1.0.0
lane: sfw
class: enemies (genesis families — data first)
status: ACTIVE lesson card — the exemplar is a DATA artifact (a frozen
  genesis family), not art; no enemy art canon exists yet
consumers:
  Sylvia/Clara: family genesis authoring (seeded tables, behaviour
    blocks as data)
  Iris: only when a family member gets a plate — the characters/
    environments registers govern the pixels
  Mira: rubric — family coherence against the genesis record
changelog:
  1.0.0 2026-11-03 — from SFW pipes Stage 3 (D-863) + Niflheim
    FULL-DESIGN (FOEs are mechanisms).
---

# SFW Enemies — a family is a frozen record, not a roster of drawings

## The SHOULD-BE-SEEN standard

An enemy family is authored ONCE as a genesis record: a seeded
variant table + per-member stat/behaviour blocks as data, frozen
under a genesis hash. Same seed → byte-identical family output
across processes; a tampered pin is refused (`genesis_mismatch`) at
the pipe gate. Generation proposes family *members* inside the
frozen table's ranges; out-of-range proposals are refused typed at
Freeze, never silently clamped. The family's art budget follows the
game's design law:

- **Niflheim FOEs are mechanisms, not characters** (art bible §7.1):
  each floor's boss is a great mechanism broken by one failure
  class. Art goes to *readable mechanism states* (a seam visible
  when diagnosed), not portraiture. A FOE plate must show the
  mechanism and its broken state legibly; a FOE "portrait" in the
  character register is a class error.
- Enemy behaviour is record data (the worked family's behaviour
  block is the slice boss's gate phases, expressed as data) — a
  model proposing behaviour invents numbers only inside the
  record's declared ranges, and the record says which values are
  example data vs canon (the worked family flags its stat values
  as example data, not canon — that flag is part of the lesson).

## Exemplar (data artifact, gate-passed)

| Artifact | Gate | What it teaches |
|---|---|---|
| The Borrowed Hoard family — genesis record + emitted tables `~/workspace/content-factory-20261103/sfw/evidence/stage3/hoard-table.json` (input family sha256 `6a303a45…e6ae3b5`) | SFW pipes Stage 3 gate (D-863): genesis hash `375b9ffa…` pinned; byte-identical tables across three independent runs (run-genesis{,-2,-3}.json); tampered pin refused | Genesis discipline end-to-end: author the family as data, pin the hash, emit deterministically. Enemy "generation" in this lane is table emission + (later) plates against the frozen record. |

## Failure museum

| Defect class | Evidence | The lesson |
|---|---|---|
| **Silent range violation** (the failure this class is built to refuse): a variant outside the family table's ranges accepted or clamped without a record | Stage 3 adversarial design (tamper case in the same evidence dir) | Refusal is typed and at Freeze; a clamped enemy is a corrupted record that still looks plausible — the worst failure shape in a data-first pipeline. |

## Canon constraints as data

- Family record: genesis seed, variant table (ranges per axis),
  stat/behaviour blocks per member, `example_data` flags where
  values are illustrative, genesis hash pin.
- Per-game application: Niflheim = 17 FOEs (one per floor) + the
  Niflhel seal encounter; Stratum I exists in the slice; the other
  16 are genesis-first when commissioned. Versemend = one trial
  construct per region (the Hollow Guest is Domain 1's, in the
  slice). Light Show and Desperado have no enemy class in this
  sense (Desperado's duelists are characters; Light Show has no
  combat — PREP-REPORT §2A).

## OPST topic descriptors

- `descriptor-enemy-family.txt` — for Sylvia/Clara: the genesis
  authoring brief in descriptor form (ranges declared before
  members, behaviour as data, example-data flags mandatory).
