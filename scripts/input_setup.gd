extends Node
## Registers every input action at boot (autoload).
##
## Contract: idempotent; called once before the main scene reads input.
## Actions are registered in code so the project file carries no
## serialised event blobs. Physical keys: WASD/arrows move, J attack,
## K / Space dodge, L / E shift (cycle form), 1/2/3 direct form,
## F / Enter interact, Esc pause, R restart at death/ending screens.

const ACTIONS: Dictionary = {
	"move_left": [KEY_A, KEY_LEFT],
	"move_right": [KEY_D, KEY_RIGHT],
	"move_up": [KEY_W, KEY_UP],
	"move_down": [KEY_S, KEY_DOWN],
	"attack": [KEY_J],
	"dodge": [KEY_K, KEY_SPACE],
	"shift": [KEY_L, KEY_E],
	"form_1": [KEY_1],
	"form_2": [KEY_2],
	"form_3": [KEY_3],
	"interact": [KEY_F, KEY_ENTER],
	"pause": [KEY_ESCAPE],
	"confirm": [KEY_R],
}


func _ready() -> void:
	register_actions()


## Adds any missing action and its key events. Safe to call twice.
func register_actions() -> void:
	for action_name: String in ACTIONS:
		if not InputMap.has_action(action_name):
			InputMap.add_action(action_name)
		var keys: Array = ACTIONS[action_name]
		for keycode: int in keys:
			var already: bool = false
			for existing: InputEvent in InputMap.action_get_events(action_name):
				if existing is InputEventKey and existing.physical_keycode == keycode:
					already = true
			if not already:
				var event: InputEventKey = InputEventKey.new()
				event.physical_keycode = keycode
				InputMap.action_add_event(action_name, event)
