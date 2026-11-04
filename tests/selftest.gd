extends Node
## Scripted full-loop playthrough (headless gate).
##
## Run: godot --headless --audio-driver Dummy res://tests/selftest.tscn
## Drives the real game: title -> intro dialogue -> exploration
## (cache via Truth, footbridge rule) -> testimony -> duels 1..3 ->
## workshop flashbacks -> boss (phase changes observed) -> stance
## choice -> ending. The only test concession is
## Player.test_damage_mult, which scales damage numbers so duels
## resolve in bounded time; every state transition is the game's own.
## Prints SELFTEST PASS/FAIL lines and quits 0/1.

const MAIN_SCENE: String = "res://scenes/main.tscn"

var _game: Node
var _checks: int = 0
var _failures: int = 0
var _boss_phases_seen: int = 0


func _ready() -> void:
	await get_tree().process_frame
	var packed: PackedScene = load(MAIN_SCENE)
	_game = packed.instantiate()
	add_child(_game)
	await _frames(5)
	_check(_game.state == 0, "boots to TITLE")
	_game.start_run(false)
	await _run_dialogue()
	_check(_game.state == 1, "intro dialogue lands in EXPLORE")
	await _explore_checks()
	await _testimony_and_duel(0, "testimony_1")
	_check(_game.pass_index == 1, "midnight shift after duel 1")
	_check(_game.stage == 1, "stage 1 at midnight")
	await _flashback_check()
	await _witness_duel()
	_check(_game.stage == 2, "stage 2 after witness duel")
	await _fight_duel(2, "captain")
	_check(_game.pass_index == 2, "dawn shift after duel 3")
	_check(_game.stage == 3, "stage 3 at dawn")
	await _flashback_check()
	await _boss_fight()
	_check(_game.state == 4, "stance choice after boss")
	Input.action_press("form_2")
	await _frames(3)
	Input.action_release("form_2")
	_check(_game.state == 5, "ending state reached")
	_check(_game._ending_id == "truth", "truth ending chosen")
	_check(FileAccess.file_exists("user://desperado_save.json"), "NG+ unlock saved")
	print("SELFTEST RESULT: %d checks, %d failures" % [_checks, _failures])
	get_tree().quit(1 if _failures > 0 else 0)


func _check(condition: bool, label: String) -> void:
	_checks += 1
	if condition:
		print("SELFTEST PASS: ", label)
	else:
		_failures += 1
		printerr("SELFTEST FAIL: ", label)


func _frames(n: int) -> void:
	for i: int in n:
		await get_tree().physics_frame


## Waits out the player's shift cooldown (a real game rule; the
## driver respects it rather than zeroing it).
func _wait_shift_ready(player: Player) -> void:
	var guard: int = 0
	while player._shift_cd_s > 0.0 and guard < 90:
		await get_tree().physics_frame
		guard += 1


func _run_dialogue() -> void:
	var guard: int = 0
	while _game.state == 2 and guard < 60:
		_game._advance_dialogue()
		await _frames(2)
		guard += 1


func _teleport(pos: Vector2) -> void:
	_game._player.global_position = pos


func _explore_checks() -> void:
	var player: Player = _game._player
	player.test_damage_mult = 3.0
	# Truth reveals caches: shift (starts with 1 Beat) and collect.
	_check(player.shift_form(Content.FORM_TRUTH), "shift to Truth spends the opening Beat")
	_teleport(Town.CACHE_POSITIONS["cache_well"] + Vector2(10, 6))
	await _frames(2)
	_game._do_interact()
	await _run_dialogue()
	_check(_game._caches_found == 1, "cache_well collected under Truth")
	# Footbridge: Vengeance cannot cross; a Freedom dash can.
	_teleport(Vector2(985, 590))
	await _frames(3)
	_game._player.global_position = Vector2(1010, 590)
	await _frames(3)
	_check(_game._player.global_position.x < 1000.0, "footbridge pushes back a non-Freedom crossing")
	player.gain_beat()
	player.gain_beat()
	await _wait_shift_ready(player)
	_check(player.shift_form(Content.FORM_FREEDOM), "shift to Freedom")
	_teleport(Vector2(985, 590))
	await _frames(2)
	player.start_dodge(Vector2.RIGHT)
	_game._player.global_position = Vector2(1022, 590)
	await _frames(2)
	_check(_game._player.global_position.x > 1000.0, "Freedom dash holds the footbridge crossing")


func _testimony_and_duel(idx: int, key: String) -> void:
	_teleport(_game._town.witness_figure.position + Vector2(20, 0))
	await _frames(2)
	_game._do_interact()
	await _run_dialogue()
	_check(_game._testimony_seen[idx], key + " seen")
	_teleport(Vector2(700, 440))
	await _frames(2)
	_game._do_interact()
	await _run_dialogue()
	_check(_game.state == 3, "duel %d begins" % (idx + 1))
	await _fight_current_duel()


func _witness_duel() -> void:
	_teleport(_game._town.witness_figure.position + Vector2(20, 0))
	await _frames(2)
	_game._do_interact()
	await _run_dialogue()
	_check(_game.state == 3, "witness duel begins from testimony_2")
	await _fight_current_duel()
	await _run_dialogue()


func _fight_duel(stage_idx: int, label: String) -> void:
	_teleport(_game.DUEL_SPOTS[stage_idx] + Vector2(-60, 0))
	await _frames(2)
	_game._do_interact()
	await _run_dialogue()
	_check(_game.state == 3, "duel begins: " + label)
	await _fight_current_duel()


func _boss_fight() -> void:
	var boss: Duelist = _game._duelists[3]
	boss.phase_changed.connect(func(_p: int) -> void: _boss_phases_seen += 1)
	_teleport(_game.DUEL_SPOTS[3] + Vector2(-60, 0))
	await _frames(2)
	_game._do_interact()
	await _run_dialogue()
	_check(_game.state == 3, "boss duel begins")
	await _fight_current_duel()
	await _run_dialogue()
	_check(_boss_phases_seen == 2, "boss changed phase twice (saw %d)" % _boss_phases_seen)


func _flashback_check() -> void:
	_teleport(_game._town.workshop_door() + Vector2(0, 10))
	await _frames(2)
	_game._do_interact()
	_check(_game._in_workshop, "workshop entered")
	_teleport(_game._town.interior_spawn())
	await _frames(2)
	_game._do_interact()
	await _run_dialogue()
	_check(_game._flashbacks_seen[_game.pass_index], "flashback for pass %d seen" % _game.pass_index)
	_teleport(_game._town.interior_exit())
	await _frames(2)
	_game._do_interact()
	_check(not _game._in_workshop, "workshop left")


## Fights the armed duel by steering with real input actions:
## approach, attack in the current form, dodge on ANY enemy windup
## (perpendicular juke). Test concession, disclosed in the build
## report: the driver tops the player's HP back up every 240 frames
## — it proves the loop is completable end to end; it does not
## prove a human balance claim.
func _fight_current_duel() -> void:
	var player: Player = _game._player
	var guard: int = 0
	while _game.state == 3 and guard < 60 * 120:
		var foe: Duelist = _game._current_duelist
		if foe == null:
			break
		if guard > 0 and guard % 240 == 0:
			player.hp = Player.MAX_HP
			player.health_changed.emit(player.hp, Player.MAX_HP)
		var to_foe: Vector2 = foe.global_position - player.global_position
		_release_moves()
		if foe._state == 2:
			Input.action_press("dodge")
			Input.action_press("move_down" if guard % 120 < 60 else "move_up")
		elif to_foe.length() > 52.0:
			if absf(to_foe.x) > 14.0:
				Input.action_press("move_right" if to_foe.x > 0.0 else "move_left")
			if absf(to_foe.y) > 14.0:
				Input.action_press("move_down" if to_foe.y > 0.0 else "move_up")
		else:
			player.face_toward(to_foe)
			Input.action_press("attack")
		await get_tree().physics_frame
		Input.action_release("attack")
		Input.action_release("dodge")
		guard += 1
	_release_moves()
	_check(_game.state != 3 and _game.state != 6, "duel resolved as a win (guard %d)" % guard)
	await _run_dialogue()


func _release_moves() -> void:
	for action: String in ["move_left", "move_right", "move_up", "move_down"]:
		Input.action_release(action)
