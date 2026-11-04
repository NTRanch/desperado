---
pack: sfw/characters-portraits
version: 1.0.0
lane: sfw
class: characters/portraits (Niflheim + Versemend teaching games)
status: ACTIVE lesson card — the pipes' deterministic gates and the
  Owner's eye remain the authority; this card teaches, it does not gate
consumers:
  Iris: descriptor files verbatim + exemplars as IPA references (0.15)
  Mira: SHOULD standard + failure museum as first-pass review rubric
  Clara/Sylvia: canon-constraints-as-data for character records
changelog:
  1.0.0 2026-11-03 — initial card, distilled from the D-836 canon
    packs as ruled at D-840–D-845 and the D-836 art bible (§8 budgets
    adopted D-846). No content beyond those records.
---

# SFW Characters / Portraits — how a teaching-game portrait is made

## The SHOULD-BE-SEEN standard

A portrait in this class is an emission of a written character record
(art bible §2), never a lucky generation. It must show, at phone size:

1. **The record, visible.** Every load-bearing attribute the record
   names — age, hair (colour, arrangement, mass), skin tone, eye
   colour, the silhouette key (the one tool-of-office shape that must
   read at sprite size) — is present and correct. What the prompt
   does not name, the model supplies from its priors, and the priors
   are wrong often enough that *unnamed = uncontrolled* (law,
   D-843). Canon prompts name load-bearing attributes — skin tone
   and hair first.
2. **The game's palette, locked.** Niflheim Stratum I: iron grey,
   ice blue, stone; tally red is the *lone* warm accent (a cord, a
   seal, a banner — one element). Versemend Lamplit Parishes:
   parchment, lamp-amber, ink-blue, leaf-green, re-weighted per
   region. A portrait whose dominant colours leave the lock is
   drift, whatever its other merits.
3. **Whole-body expression.** An expression variant differs in face,
   posture, hands, stance, and weight — all five (Owner, 2026-10-06;
   art bible §2 expression set). A face-only change fails record
   review and fails this class.
4. **No text, ever.** No words, letters, numerals, pseudo-script —
   anywhere, including on clothing, books, and signage (art bible
   §0). Text is typeset by engine code or it does not ship.
5. **Framing.** Full body or declared bust, the silhouette key
   legible at thumbnail size; generation at 2× display size;
   deterministic finishing (palette snap, declared-region repair)
   beats regeneration for a measurable defect.

## Exemplars (eye-passed; referenced by path + hash, never copied)

| Id | Artifact | Gate | Seed | Why it is a keeper |
|---|---|---|---|---|
| N1a | `~/workspace/educational-games-art-20261103/niflheim-canon/N1a-oathwarden-teaching.png` sha256 `8a899957…2ea` | ADOPTED D-840 (2026-11-03) | 711001 | Cold palette exact; tally-red cord the lone warm accent; ledger + satchel silhouette reads at thumbnail; raised-hand *teaching* gesture — posture and hands carry the expression, not the face alone. Named deviations (kept as calibration): reads younger than her fifties (register softens age — hence law 1: name age); hair grey-white not grey-streaked dark; an unrequested floating ice crystal at the raised hand (hence the descriptor's explicit negative). |
| V1a | `~/workspace/educational-games-art-20261103/versemend-canon/V1a-lampkeeper-teaching.png` sha256 `bc27dd5b…16` | ADOPTED D-843 (2026-11-03) | 721001 | Lamp-staff silhouette key unmistakable at any size; braid, ink-blue sash, amber cloak; whole-body open-hand teaching gesture; warm storybook register held throughout. Deviations: background an ornate framed arch, not the village lane (poster presentation); palette leans orange-red over parchment. |
| N-slice | `~/workspace/niflheim-playable-20261103/build/assets/art/portrait.png` | shipped slice, as-built evidence (D-848 programme) | — | The canon register surviving contact with a shipping build: the portrait as the game actually presents it. Evidence class: (a) shipped-slice art direction. |
| V-slice | `~/workspace/versemend-playable-20261103/assets/keeper.png` | shipped slice, as-built evidence | — | Same role for Versemend: the Keeper as built, beside her canon anchor — drift between the two is measured, not assumed. |

Production recipe of record for the anchors (keeper-chains.json in
each canon dir): checkpoint `waiIllustriousSDXL_v170`, sampler
euler_ancestral/normal, 30 steps, CFG 6.0; expression variants
IPAdapter-conditioned on the (a) variant at IPA 0.15 (D-826 estate
default). Database generation runs through **Iris**
(Illustrious-XL-v1.1) per D-865 — same Illustrious family, same
descriptor text; the anchors' checkpoint is provenance, not a
substitution.

## Failure museum (honest FAILs, defect named — same workdirs)

| Artifact | Defect class | The lesson |
|---|---|---|
| `niflheim-canon/N1c-oathwarden-pleased.png` (seed 711003) | **Pseudo-text + wardrobe contradiction**: robe gained a high slit with pseudo-lettering marks on the exposed thigh (art bible §0 violation); grin reads sly, not warm; floating crystal recurs | Generation will letter skin/clothing if any text-shaped region is invited; keep text tokens and text-like ornament out entirely, and negative pseudo-script. A pleased expression is whole-body relaxed stance, not a bigger smile. |
| `versemend-canon/V1b-lampkeeper-weary.png` (seed 721002) | **Identity drift at IPA 0.15**: hooded red cloak appears, hair darkens, dress turns golden, line flattens — "a relative of V1a's keeper, not the same woman" | IPA at 0.15 holds palette and props, not face and wardrobe. Canon-grade expression sets need the pose-map half of the recipe (ControlNet) or record-level finishing; do not ask conditioning custody to cover what the prompt left unsaid. |
| `versemend-canon/V1c-lampkeeper-pleased.png` (seed 721003) | **Unnamed-attribute drift**: laughter lands fully, but skin tone renders markedly deeper/orange than V1a — the prompt never named skin tone | The D-843 law's evidence. Every load-bearing attribute is named in the record AND the prompt, skin tone and hair first. |

## Canon constraints as data (for Clara/Sylvia record authoring)

- Character record fields (art bible §2): identity (id, game, name,
  role, domain, first_seen); palette roles as hex (skin, hair, eye,
  garment_primary, garment_secondary, accent_metal, accent_cloth) +
  negative palette; silhouette (build, hair_mass, outline_key);
  features (each distinguishing mark: location + shape + colour);
  wardrobe named sets with garment-class negatives stored per set
  (a garment named in the positive is not a ban on its opposite —
  the D-828 lesson, recorded in the NSFW clothing pack, applies as
  mechanics in both lanes); expression set with ALL FIVE fields
  (face, posture, hands, stance, weight) per expression — an entry
  with only `face` filled fails record review.
- Niflheim palette arc: the descent darkens by stratum; Stratum I
  lock = cold surface daylight (iron grey, ice blue, stone, tally
  red lone accent). Strata II–IV locks live in the style brief.
- Versemend register: warm storybook; anchors parchment / lamp-amber
  / ink-blue / leaf-green; regions re-weight (River Country cools,
  Workshop Towns add forge-orange, the Host's Shore pales).
- Budgets (D-846, revisable on first production measurements):
  portrait puppet texture set ≤ 8 MB decoded per character; total
  art payload ≤ 220 MB (Niflheim) / ≤ 180 MB (Versemend) of the
  500 MB install cap.

## OPST topic descriptors (the text a generator is actually given)

- `descriptor-niflheim-portrait.txt` — POS/NEG pair: cold lock,
  named age/hair/skin, silhouette key, concrete-structure wording,
  floating-object and pseudo-text negatives.
- `descriptor-versemend-portrait.txt` — POS/NEG pair: warm storybook
  register, plural-architecture wording, named skin tone + hair,
  lamp-amber on ink-blue signature.

Descriptor discipline: the descriptor is appended to the subject's
own record-derived prompt; it never replaces the record. Subject
tokens come from the character record; the descriptor carries the
class/canon register only.
