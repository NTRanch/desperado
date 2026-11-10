class_name LaForma
extends RefCounted
## The Desperado's three desires (DESIGN.md — La Forma): one system,
## three expressions. Vengeance is pressure, Truth is exposure,
## Freedom is position. The form vocabulary lives here exactly once;
## the player, the bolts, and the enemies all speak it.
## Contract: form ids are stable ints — they ride on bolts — and the
## Shift cycles Vengeance -> Truth -> Freedom -> Vengeance.

enum Form { VENGEANCE, TRUTH, FREEDOM }

const FORM_COUNT: int = 3
const NAMES: Array = ["VENGEANCE", "TRUTH", "FREEDOM"]
const COLORS: Array = [
	Color(0.96, 0.38, 0.24),
	Color(0.36, 0.86, 0.96),
	Color(0.55, 0.96, 0.45),
]


## The form the Shift cycles to from the given form.
static func next_form(form: int) -> int:
	return (form + 1) % FORM_COUNT


## Player-facing form name; out-of-range ids clamp.
static func name_of(form: int) -> String:
	return String(NAMES[clampi(form, 0, FORM_COUNT - 1)])


## The form's signature colour (HUD, bolts, snap flash).
static func color_of(form: int) -> Color:
	return Color(COLORS[clampi(form, 0, FORM_COUNT - 1)])
