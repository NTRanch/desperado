---
pack: sfw/environments-plates
version: 1.0.0
lane: sfw
class: environments / background plates + textures & ornament (source plates)
status: ACTIVE lesson card — gates and the Owner's eye remain the authority
consumers:
  Iris: descriptors verbatim; exemplars as register references
  Mira: SHOULD standard + failure museum as review rubric
  Clara/Sylvia: kit anatomy + palette locks as record constraints
changelog:
  1.0.0 2026-11-03 — from the D-836 art bible §3 + canon rulings
    D-841 (Niflheim vista) and D-844 (Versemend plate).
---

# SFW Environments / Plates — how a place is made

## The SHOULD-BE-SEEN standard

A place is a **kit**, not a pile of paintings (art bible §3): layers
always separated — `back` (sky/vista/depth wall), `mid`
(architecture/terrain the eye reads as place), `fore` (sparse
foreground framing) — each its own plate, so scenes compose and
parallax (proposed factors back 0.25 / mid 0.6 / fore 1.15). A plate
that cannot tile is a vista and is labelled one. Each kit declares
its light (Stratum I: cold surface daylight, iron-grey sky; Lamplit
Parishes: lamp-warm dusk) and locks 8–12 palette roles as hex;
finishing snaps plates to the lock, and a plate with >2% of pixels
outside the lock's hue families after the snap is a drift reject
(proposed threshold, D-846 working budgets) — returned with the
measurement, not an opinion.

**Wording laws (measured, from the canon rounds):**

1. **Name structures concretely, or the model's prior supplies a
   modern object.** "Signal tower" rendered as a red radio lattice
   mast in both seeds, both games. Production wording: **"stone
   beacon turret"**; a tally bridge is named as a structure, not an
   implication (D-841 production law).
2. **Plural-architecture wording for settlements.** A "town" prompt
   without frontage/stalls/lane tokens collapsed to a single house;
   the adopted plate's wording named guildhall frontage, market
   stalls, a lane of lamp-posts (D-844 finding 2).
3. **Accent discipline.** One warm accent family per cold plate
   (tally-red banners/doors in Stratum I). Warm window-light
   everywhere breaks the lock even when each window is plausible.

## Exemplars (eye-passed)

| Id | Artifact | Gate | Seed | Why it is a keeper |
|---|---|---|---|---|
| N2b | `~/workspace/educational-games-art-20261103/niflheim-canon/N2b-stratum1-vista.png` sha256 `f6c67fa9…f5ff` | ADOPTED D-841 | 712002 | Layered exactly as kitted: frozen-river foreground, gatehouse with stone tower mid, peaks behind; small red door accents hold the lone-warm-accent rule. Kept deviations (calibration): the far signal structure is STILL a lattice mast with guy-wires — the wording law above is this plate's own lesson; amber windows run warm (hearth-light, arguable). |
| V2b | `~/workspace/educational-games-art-20261103/versemend-canon/V2b-parishes-plate.png` sha256 `91f118c9…d91` | ADOPTED D-844 | 722002 | The town vista as briefed: guildhall-scale frontage, lit market stalls, foreground lamp-post, dusk gradient sky, depth layered to the hills. Minor: stalls read slightly as wheeled food-carts; horizon sunset band runs orange-strong. |
| V2a | `~/workspace/educational-games-art-20261103/versemend-canon/V2a-parishes-plate.png` sha256 `bd0b15e8…385` | retained as palette-lock reference, D-844 | 722001 | Lamp-amber-on-ink-blue signature exact; layering and reflections clean. NOT the canon plate (content collapsed to one waterside house) — it serves as the palette reference a drift check compares against. |

## Failure museum

| Artifact | Defect class | The lesson |
|---|---|---|
| `niflheim-canon/N2a-stratum1-vista.png` (seed 712001) | **Prior-supplied modern structure**: signal tower = oversized red lattice mast, modern read; no tally bridge (a glowing blue stream, brighter than palette, carries the eye instead); gatehouse reads as a house cluster | Concrete-structure wording (law 1); name the bridge; a glow element brighter than the lock steals the plate's focal order — cap emissive accents in the prompt and the palette snap. |
| V2a (above, as content) | **Settlement collapse**: plural place → single house | Law 2: frontage, stalls, lane — plurality must be tokenised. |

## Canon constraints as data

- Kit record: layers (back/mid/fore), prop families 6–10 per kit in
  the kit palette (Stratum I: gatehouse, tally bridge, signal tower
  — read *stone beacon turret*; Parishes: lamp-posts, guildhall
  frontage, mill), tile/repeat declaration per plate, lighting state
  per kit; dawn/night variants are palette-and-light re-grades of
  the same plates, never new paintings.
- Palette arc (Niflheim): I cold surface daylight → II brass/oil
  blacks → III treaty-port colours → IV near-monochrome, one accent
  per floor → Niflhel unlit except engine-light. Each stratum locks
  its own palette under the arc.
- Budgets (D-846): background kit ≤ 40 MB on disk (Niflheim) /
  ≤ 32 MB (Versemend); textures resident per scene ≤ 64/48 MB.

## OPST topic descriptors

- `descriptor-niflheim-vista.txt`, `descriptor-versemend-plate.txt`
  in this pack dir (POS/NEG pairs carrying the wording laws).
