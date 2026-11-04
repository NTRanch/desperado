class_name Content
extends RefCounted
## All authored content for Desperado, as data.
##
## Contract: pure data + lookups; no scene access, no state. Dialogue
## lines are arrays of {speaker, text} dictionaries. Duel definitions
## carry the numbers duelist.gd consumes; behaviour never hides here.
## English only (production rule). No real persons or studio names.

# -- Forms (La Forma) ---------------------------------------------------

const FORM_VENGEANCE: int = 0
const FORM_TRUTH: int = 1
const FORM_FREEDOM: int = 2

const FORM_NAMES: Array[String] = ["Vengeance", "Truth", "Freedom"]
const FORM_BLURBS: Array[String] = [
	"Dual pistols into Gatling pressure. Fast, close, relentless.",
	"Rifle shots that expose weak points — and hidden things.",
	"Burst movement and scatter. The form that opens routes.",
]
const FORM_COLORS: Array[Color] = [
	Color(0.92, 0.36, 0.22),
	Color(0.35, 0.72, 0.95),
	Color(0.45, 0.88, 0.52),
]

# -- Passes (the town's three Shifts) ------------------------------------

const PASS_NAMES: Array[String] = ["Dusk Shift", "Midnight Shift", "Dawn Shift"]
const PASS_MODULATE: Array[Color] = [
	Color(1.02, 0.78, 0.58),
	Color(0.42, 0.52, 0.82),
	Color(0.98, 0.82, 0.68),
]
const PASS_SKY: Array[Color] = [
	Color(0.98, 0.55, 0.32),
	Color(0.07, 0.09, 0.24),
	Color(0.85, 0.62, 0.45),
]

# -- Characters -----------------------------------------------------------

const CHARACTERS: Dictionary = {
	"heir": {
		"name": "The Heir",
		"coat": Color(0.23, 0.16, 0.12),
		"skin": Color(0.87, 0.65, 0.50),
		"hair": Color(0.12, 0.09, 0.08),
		"accent": Color(0.85, 0.62, 0.25),
	},
	"enforcer": {
		"name": "Vex Marlow, Combine Enforcer",
		"coat": Color(0.16, 0.18, 0.24),
		"skin": Color(0.72, 0.52, 0.40),
		"hair": Color(0.55, 0.12, 0.10),
		"accent": Color(0.65, 0.68, 0.75),
	},
	"witness": {
		"name": "Pella Quinn, the False Witness",
		"coat": Color(0.30, 0.26, 0.20),
		"skin": Color(0.90, 0.70, 0.55),
		"hair": Color(0.35, 0.22, 0.12),
		"accent": Color(0.55, 0.48, 0.30),
	},
	"captain": {
		"name": "Captain Rook, Combine Reclamation",
		"coat": Color(0.20, 0.14, 0.20),
		"skin": Color(0.60, 0.44, 0.34),
		"hair": Color(0.75, 0.72, 0.68),
		"accent": Color(0.70, 0.30, 0.55),
	},
	"agent": {
		"name": "Agent Sable, the Framing Hand",
		"coat": Color(0.10, 0.10, 0.13),
		"skin": Color(0.82, 0.60, 0.46),
		"hair": Color(0.05, 0.05, 0.06),
		"accent": Color(0.90, 0.85, 0.70),
	},
	"mother": {
		"name": "Mother Adler (memory)",
		"coat": Color(0.40, 0.30, 0.22),
		"skin": Color(0.88, 0.66, 0.52),
		"hair": Color(0.25, 0.16, 0.10),
		"accent": Color(0.85, 0.62, 0.25),
	},
}

# -- Duels -----------------------------------------------------------------
# pattern: which attack kinds the duelist mixes; phases only for the boss.
# answer_form: damage taken x1.6 from it. punished_form: damage x0.35.

const DUELS: Array[Dictionary] = [
	{
		"id": "enforcer",
		"title": "Duel I — The Enforcer",
		"hp": 130,
		"speed": 96.0,
		"melee_damage": 14,
		"ranged_damage": 8,
		"windup_s": 0.62,
		"patterns": ["melee", "melee", "burst"],
		"surrender_hp": 0,
	},
	{
		"id": "witness",
		"title": "Duel II — The Witness",
		"hp": 90,
		"speed": 104.0,
		"melee_damage": 8,
		"ranged_damage": 9,
		"windup_s": 0.5,
		"patterns": ["shot", "feint", "shot", "melee"],
		"surrender_hp": 12,
	},
	{
		"id": "captain",
		"title": "Duel III — The Captain",
		"hp": 175,
		"speed": 112.0,
		"melee_damage": 16,
		"ranged_damage": 10,
		"windup_s": 0.52,
		"patterns": ["melee", "burst", "dash", "melee", "shot"],
		"surrender_hp": 0,
	},
	{
		"id": "agent",
		"title": "Final Duel — The Framing Hand",
		"hp": 330,
		"speed": 108.0,
		"melee_damage": 18,
		"ranged_damage": 11,
		"windup_s": 0.46,
		"patterns": ["burst", "melee", "dash", "shot"],
		"surrender_hp": 0,
		"phases": [
			{"answer_form": FORM_TRUTH, "punished_form": FORM_VENGEANCE},
			{"answer_form": FORM_FREEDOM, "punished_form": FORM_TRUTH},
			{"answer_form": FORM_VENGEANCE, "punished_form": FORM_FREEDOM},
		],
	},
]

# -- Dialogue ---------------------------------------------------------------
# Each sequence is an array of [speaker_id, line] pairs.

const DIALOGUE: Dictionary = {
	"intro": [
		["heir", "San Aurelia. Ten years, and the dust kept my name better than the town did."],
		["heir", "They said I murdered my family. Tonight the Combine learns what a frame is worth."],
		["heir", "The Desperado still answers my hand. One night. Three scores. Then the truth."],
	],
	"pre_enforcer": [
		["enforcer", "Adler whelp. The Combine pays well for your head — again."],
		["heir", "You were there that night, Marlow. I remember the coat."],
		["enforcer", "Then remember this too, boy: I finish jobs."],
	],
	"post_enforcer": [
		["enforcer", "Enough — enough! I was muscle, nothing more. Quinn... ask Quinn what she saw. She was paid to see it."],
		["heir", "The witness. Of course. Midnight, then. The town shifts, and so does her story."],
	],
	"testimony_1": [
		["witness", "I saw you. That night. In the workshop, with the Desperado in your hand and your family on the floor."],
		["heir", "You saw a boy of nine in a burning room, Pella. What did the Combine pay for your eyes?"],
		["witness", "I — I saw what I said I saw. Leave me be."],
	],
	"flashback_1": [
		["mother", "Hold it like you mean to build, not to kill. A Deseo is a promise your hand makes."],
		["heir", "Mother... The workshop remembers her voice better than I do."],
	],
	"testimony_2": [
		["witness", "Stop following me. The second telling is worse — they made me change the hour. Midnight, I said. It was dusk."],
		["heir", "Dusk. I was at the water tower at dusk, Pella. Half the town saw me."],
		["witness", "Then half the town was paid to forget! Ask me again at the plaza — no. No more words. Draw, then!"],
	],
	"post_witness": [
		["witness", "I yield! I yield. The agent wrote my testimony before the fire was out. Sable. It was always Sable."],
		["heir", "Then the Combine will send someone to tidy up. They always do."],
	],
	"flashback_2": [
		["mother", "Vengeance, Truth, Freedom — one gun, three desires. The kata is choosing, child. Not once. Every breath."],
		["heir", "La Forma. Choose the desire that fits the moment, and keep the kata flowing."],
	],
	"pre_captain": [
		["captain", "Loose ends, heir. You are one. Quinn is another, but you will do first."],
		["heir", "Reclamation. The Combine's word for a broom. Come and sweep, Captain."],
	],
	"post_captain": [
		["captain", "Sable... will not... forgive this failure. Dawn, heir. The tower. He will want to finish his own frame."],
		["heir", "Dawn, then. The last Shift. The town, my gun, and the truth — all changing shape at once."],
	],
	"flashback_3": [
		["mother", "If a Sable ever comes for this family, remember: a frame is a story told about a shape. Change the shape. Break the story."],
		["heir", "Change the shape. Break the story. I understand, Mother. At last, I understand."],
	],
	"pre_agent": [
		["agent", "The Adler heir. My finest composition. A murderer at nine — the whole sector believed it."],
		["heir", "You framed a child, Sable. You murdered gunsmiths who would not kneel to the Combine."],
		["agent", "And I would do it again for the fortune it made. Let us see if the Desperado remembers its smith."],
	],
	"post_agent": [
		["agent", "The kata... was never in my account of you. I framed a boy. I never priced the man."],
		["heir", "It is over. The night is done shifting. Now I choose the shape I stay in."],
	],
	"cache_found": [
		["heir", "A Deseo cache — my father's hand. The town kept more secrets than the Combine ever bought."],
	],
}

const ENDINGS: Dictionary = {
	"revenge": {
		"title": "Ending — Revenge",
		"lines": [
			"Sable dies at dawn beneath the water tower he once watched from.",
			"The sector calls it justice. The heir calls it arithmetic.",
			"San Aurelia keeps his name on a wanted poster — and this time, he earned it.",
		],
	},
	"truth": {
		"title": "Ending — Truth",
		"lines": [
			"Sable lives — long enough to confess before the sector court, with Quinn's true testimony beside him.",
			"The frame breaks in daylight. The Adler name is cleared.",
			"The Desperado goes quiet in its holster: a tool again, not a verdict.",
		],
	},
	"freedom": {
		"title": "Ending — Freedom",
		"lines": [
			"The heir walks out of San Aurelia before the dust settles, Sable's fate left to the town that believed him.",
			"No poster, no court, no grave he has to visit. Just the road and a gun that changes shape.",
			"Some say he still answers when a town like this one calls. Some say that is enough.",
		],
	},
	"release": {
		"title": "Ending — Release",
		"lines": [
			"Every cache opened, every secret kept — the heir lowers the Desperado and lets Sable run.",
			"Not mercy. Accounting. A frame is a story, and he is done being written by other men.",
			"At dawn the workshop door opens for the first time in ten years. The heir goes home.",
		],
	},
}

# -- Caches ------------------------------------------------------------------
# Positions live in town.gd (they are geometry); ids + hints live here.

const CACHE_IDS: Array[String] = [
	"cache_well", "cache_tower", "cache_stall",
	"cache_workshop", "cache_saloon", "cache_gap",
]
const CACHE_HINTS: Dictionary = {
	"cache_well": "Something glints at the old well.",
	"cache_tower": "The tower's shadow hides a seam.",
	"cache_stall": "A market stall, shuttered since the fire.",
	"cache_workshop": "Behind the workshop, where the apprentices hid their mistakes.",
	"cache_saloon": "Under the saloon's broken piano.",
	"cache_gap": "Across the broken footbridge — only Freedom crosses.",
}


## Returns the duel definition for an index, or an empty Dictionary.
static func duel_def(index: int) -> Dictionary:
	if index < 0 or index >= DUELS.size():
		return {}
	return DUELS[index]


## Returns the dialogue sequence for a key, or an empty Array.
static func dialogue(key: String) -> Array:
	if not DIALOGUE.has(key):
		return []
	return DIALOGUE[key]
