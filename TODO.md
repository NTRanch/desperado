# Desperado — TODO / Improvement Programme

Game Off 2026 entry. Theme: SHIFT. Deadline: **2026-12-01 13:37 PST**.
Current state: playable Dusk slice (Godot 4, 2D run-and-gun, 4800 px level,
Rifleman + Rusher, framing-agent gate duel → "DUSK SHIFT CLEAR").
Headless smoke baseline: **30 checks / 0 failures** — keep it there or better;
every art-wiring change re-runs the smoke.

## Art programme (Owner-approved, 5 stages)

- [ ] **Stage 1 — style lock + hero sprite set** *(in flight on
  `pax/art-stage1-20261109`, Owner verdict pending)*: STYLE bible
  (`docs/art/STYLE.md`) from the ruled San Aurelia plates — fixed palette per
  pass, ~48 px Slug-proportioned hero, silhouette scale, 3 reference frames.
  Hero set: idle / run / aim-up / crouch / jump / shoot / dodge / SHIFT /
  hurt / death (PNG frames + sheet + .aseprite sources), wired to the slice's
  sprite contract. Production route: high-res generation → downscale →
  palette-quantize → Aseprite cleanup.
- [ ] **Stage 2 — enemies + environment family**: Rifleman / Rusher sprite
  sets and the Dusk environment family, same production route and palette.
- [ ] **Stage 3 — Midnight / Dawn**: palette grade + lighting + layout remix
  of the Dusk environment family (not separate builds).
- [ ] **Stage 4 — juice pass**: brass casings, dust, bolt trails, hit-stop,
  muzzle flash, SHIFT after-images.
- [ ] **Stage 5 — SFX**: wired from the licensed audio library / Freesound
  bench (per-file attribution kept).

## Feel gate

- [ ] **Owner playtest on primo still owed** — feel is Owner-unverified.
  Controls: A/D move, W aim up, S crouch, Space jump, Z/J shoot,
  X/L/E shift (La Forma), C/K dodge.
- [ ] Balance pass on Beats economy / SHIFT chain window (1 Beat per SHIFT,
  1.0 s chain window, cap 8) after the feel gate.

## Gameplay depth

- [ ] Midnight pass (second level) — not yet built.
- [ ] Dawn pass (finale) — not yet built.
- [ ] Deseo cache hunt: Truth form reveals the one hidden Deseo cache per
  pass — designed, not yet implemented.
- [ ] Form tuning: Vengeance Gatling ramp (chain ≥ 4), Truth weak-point ×3,
  Freedom spread + i-frame burst — verify against design numbers in play.

## itch page (https://ntranch.itch.io/desperado)

- [ ] Cover image (630×500) — still absent.
- [ ] 3–5 screenshots — still absent.
- [ ] Zip-internal `README.txt` still says "solar-quantum" — fix at the next
  butler push.
- [ ] Next butler push uses the version scheme `0.1.0-<slice>` on the
  `linux` channel.
- [ ] Studio profile line still calls Desperado "a space-western arena-duel
  game" — update to match the shipped run-and-gun.

## Engineering

- [ ] Keep the headless smoke suite at 30/0 or better on every commit.
- [ ] Merge the art Stage 1 branch once the Owner verdict lands.
