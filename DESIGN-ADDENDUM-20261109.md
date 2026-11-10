# Desperado — design addendum 2026-11-09: the scroller form

The Owner ruled the jam build's form on 2026-11-09: a 2D
side-scroller in the Metal Slug run-and-gun grammar, gameplay
first, placeholder shapes, the Shift system as designed. This
addendum records what that ruling changes relative to DESIGN.md
and what it deliberately does not. DESIGN.md remains the design
of record for fiction, theme, and the La Forma mechanic.

## What carries from DESIGN.md unchanged

- **The mechanic is the theme.** La Forma exactly as designed:
  last-instant dodge/parry earns a Beat; Beats are spent to
  Shift (morph) mid-combo; shift on the beat or the kata breaks
  (the Shift chain increments inside the window, resets outside
  it). The three morphs are the one system's three expressions:
  Vengeance (pressure — fast fire, Gatling ramp at chain ≥ 4),
  Truth (exposure — piercing; marks weak points for ×3; reveals
  hidden Deseo caches), Freedom (position — spread shot that is
  also a burst of movement with i-frames).
- **The shift-snap** as the one effect vocabulary: hit-stop,
  form-tinted snap flash and silhouette ghost, camera shake —
  spent on every morph and, smaller, on every Beat.
- **One block, three passes** (Dusk / Midnight / Dawn Shifts),
  the duel ladder (Combine enforcer, false witness, framing
  agent boss), caches as the replay depth, the NG+ "High Noon"
  remix, and the four stance endings as the full entry's plan.
- **The fiction**: the Adler heir, the Morrow Combine, San
  Aurelia, the Desperado as the family's morphing gun.

## What the scroller form changes (this slice)

- **Traversal replaces the plaza investigation loop** for the
  slice: the block reads left-to-right — run, jump, crouch,
  8-way aim (up, up-diagonal, low crouch line, air down) — with
  an upper line of awnings and rooftops above the street.
- **Duels become gate encounters**: at the street's end the
  arena locks and the duel happens in motion, run-and-gun
  style, instead of in a static arena. The framing agent is
  the slice's duel: aimed volley, 5-way spread, and a charge
  that must be dodged for Beats.
- **Testimony and dialogue are out of the slice's loop**; the
  false witness's shifting account belongs to the full entry's
  pass structure, not to this traversal cut.
- The slice is the **Dusk pass only**, sunset palette, one
  block (~4800 px), one cache of the planned six.

## Deliberately NOT in the slice

- Midnight and Dawn passes (palette/state shifts of the block).
- The enforcer and false-witness duels as full encounters
  (street enemies — rifleman, rusher — carry their verbs).
- Caches beyond the one rooftop Deseo cache.
- The workshop flashback room, testimony, dialogue, endings,
  NG+ High Noon, and all generated art and audio (the slice is
  placeholder shapes and silent by design; the arena build's
  media pipeline stays in the repo for the full entry).

The arena build (scenes/main.tscn and its scripts) remains in
the tree untouched; project.godot's main scene now points at
the scroller level, and the input map grew the scroller verbs
(jump, crouch, shoot; dodge re-keyed so Space is jump — see
scripts/input_setup.gd). The headless gate for this slice is
tools/smoke.gd.
