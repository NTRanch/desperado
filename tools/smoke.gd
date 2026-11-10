extends SceneTree
## Headless smoke gate for the scroller slice.
##
## Run: godot --headless --path . --script res://tools/smoke.gd
## (from the project root; --audio-driver Dummy optional, the
## slice has no audio).
##
## Drives the real level with Input.action_press — the same input
## state the keyboard produces — through: run, Vengeance fire, a
## roll-through Beat off a rifleman's bolt, a Shift inside the
## chain window (chain increments, form cycles, Beat spent), an
## upward Truth shot, a second Beat and Shift, a Freedom shot
## (5 pellets + burst velocity), then the boss duel: start_duel,
## two Beats earned off boss bolts, Truth mark (x1) and marked
## hit (x3), the boss finished through the real damage path,
## gates open, clear screen shown. Prints SMOKE PASS/FAIL per
## assertion and quits 0/1.

const LEVEL_SCENE: String = "res://scenes/scroller/level.tscn"
const INPUT_SETUP_SCRIPT: String = "res://scripts/input_setup.gd"
const MAX_FRAMES: int = 12000

var _level: ScrollerLevel
var _player: ScrollerPlayer
var _checks: int = 0
var _failures: int = 0
var _frames_run: int = 0


func _initialize() -> void:
	_ensure_input_actions()
	var packed: PackedScene = load(LEVEL_SCENE)
	if packed == null:
		print("SMOKE FAIL: level scene failed to load")
		quit(1)
		return
	_level = packed.instantiate() as ScrollerLevel
	root.add_child(_level)
	_run()


func _ensure_input_actions() -> void:
	# Autoloads may not exist under --script; registration is the
	# autoload's own idempotent code path either way.
	if InputMap.has_action("shoot"):
		return
	var setup: Node = (load(INPUT_SETUP_SCRIPT) as GDScript).new()
	setup.call("register_actions")
	setup.free()


func _check(condition: bool, label: String) -> void:
	_checks += 1
	if condition:
		print("SMOKE PASS: ", label)
	else:
		_failures += 1
		printerr("SMOKE FAIL: ", label)


func _frames(n: int) -> void:
	for i: int in n:
		await physics_frame
		_frames_run += 1


func _wait_until(cond: Callable, timeout_frames: int) -> bool:
	var waited: int = 0
	while not bool(cond.call()):
		if waited >= timeout_frames or _frames_run > MAX_FRAMES:
			return false
		await physics_frame
		_frames_run += 1
		waited += 1
	return true


func _release_all() -> void:
	for action: String in ["move_left", "move_right", "move_up", "move_down", "shoot", "dodge", "shift", "jump", "crouch"]:
		Input.action_release(action)


func _hold_toward(target_x: float) -> void:
	Input.action_release("move_left")
	Input.action_release("move_right")
	if _player.global_position.x < target_x:
		Input.action_press("move_right")
	else:
		Input.action_press("move_left")


func _first_rifleman() -> ScrollerRifleman:
	for enemy: ScrollerEnemy in _level.enemies:
		if enemy is ScrollerRifleman and is_instance_valid(enemy):
			return enemy as ScrollerRifleman
	return null


func _player_bolts() -> Array:
	return get_nodes_in_group("player_bolts")


## Teleports the player in front of the rifleman and rolls through
## its next bolt. Returns true when a Beat was earned.
func _earn_beat_from_rifleman(rifleman: ScrollerRifleman) -> bool:
	var beats_before: int = _player.beats
	_player.global_position = Vector2(rifleman.global_position.x - 260.0, 536.0)
	_player.velocity = Vector2.ZERO
	await _frames(2)
	_hold_toward(rifleman.global_position.x)
	var saw_bolt: bool = await _wait_until(func() -> bool: return get_nodes_in_group("enemy_bolts").size() > 0, 300)
	if not saw_bolt:
		_release_all()
		return false
	var near: bool = await _wait_until(func() -> bool:
		for node: Node in get_nodes_in_group("enemy_bolts"):
			if _player.global_position.distance_to((node as Node2D).global_position) < 78.0:
				return true
		return false, 300)
	if not near:
		_release_all()
		return false
	Input.action_press("dodge")
	await _frames(3)
	Input.action_release("dodge")
	var earned: bool = await _wait_until(func() -> bool: return _player.beats > beats_before, 150)
	_release_all()
	return earned


## Dodges through boss bolts (or the charge) until the player
## holds at least `want` Beats.
func _earn_beats_near_boss(want: int, timeout_frames: int) -> bool:
	var waited: int = 0
	while _player.beats < want:
		if waited >= timeout_frames or _frames_run > MAX_FRAMES:
			return false
		await physics_frame
		_frames_run += 1
		waited += 1
		if _player.is_dodging() or not is_instance_valid(_level.boss):
			continue
		var threat: bool = false
		for node: Node in get_nodes_in_group("enemy_bolts"):
			if _player.global_position.distance_to((node as Node2D).global_position) < 85.0:
				threat = true
		if _level.boss != null and bool(_level.boss.get("charging")):
			if absf(_player.global_position.x - _level.boss.global_position.x) < 130.0:
				threat = true
		if threat:
			_hold_toward(_level.boss.global_position.x)
			Input.action_press("dodge")
			await _frames(3)
			Input.action_release("dodge")
			_release_all()
	return true


## A firing position inside the arena on the boss's centre side,
## so no gate can ever stand between the player and the boss.
func _boss_side_position() -> Vector2:
	var boss_x: float = _level.boss.global_position.x
	var dir: float = 1.0 if boss_x < 4400.0 else -1.0
	var x: float = clampf(boss_x + dir * 170.0, 4140.0, 4660.0)
	return Vector2(x, 536.0)


## Repositions on the boss's centre side, faces it, and fires one
## Truth shot; true when boss HP fell.
func _fire_at_boss_once() -> bool:
	if not is_instance_valid(_level.boss):
		return false
	_player.global_position = _boss_side_position()
	_player.velocity = Vector2.ZERO
	await _frames(2)
	_hold_toward(_level.boss.global_position.x)
	await _frames(2)
	_release_all()
	var hp_before: int = _level.boss.hp
	Input.action_press("shoot")
	await _frames(3)
	Input.action_release("shoot")
	return await _wait_until(func() -> bool: return not is_instance_valid(_level.boss) or _level.boss.hp < hp_before, 110)


func _run() -> void:
	await _frames(5)
	_player = _level.player
	_check(_player != null, "level boots with a player")
	_check(_player.form == LaForma.Form.VENGEANCE, "starts in Vengeance")
	_check(_player.beats == 0 and _player.chain == 0, "starts with 0 Beats, chain 0")

	# Run right.
	var start_x: float = _player.global_position.x
	Input.action_press("move_right")
	await _frames(30)
	Input.action_release("move_right")
	_check(_player.global_position.x > start_x + 50.0, "player runs right")

	# Vengeance fire.
	Input.action_press("shoot")
	var saw_vengeance: bool = await _wait_until(func() -> bool: return _player_bolts().size() > 0, 40)
	Input.action_release("shoot")
	_check(saw_vengeance, "Vengeance fires bolts")

	# Beat 1: roll through a rifleman bolt, then Shift on the beat.
	var rifleman: ScrollerRifleman = _first_rifleman()
	_check(rifleman != null, "a rifleman is posted on the street")
	var got_beat: bool = await _earn_beat_from_rifleman(rifleman)
	_check(got_beat, "roll through a bolt earns a Beat")
	_check(_player.beats >= 1, "Beat banked (beats=%d)" % _player.beats)
	Input.action_press("shift")
	await _frames(3)
	Input.action_release("shift")
	_check(_player.form == LaForma.Form.TRUTH, "Shift cycles Vengeance -> Truth")
	_check(_player.chain == 1, "Shift inside the window: chain 1")
	_check(_player.beats == 0, "Shift spent the Beat")

	# Truth fire (aimed up, so the street stays intact).
	Input.action_press("move_up")
	Input.action_press("shoot")
	var truth_pierce: Array = [false]
	var saw_truth: bool = await _wait_until(func() -> bool:
		for node: Node in _player_bolts():
			var bolt: ScrollerBolt = node as ScrollerBolt
			if bolt != null and bolt.form == LaForma.Form.TRUTH:
				truth_pierce[0] = bolt.pierce
				return true
		return false, 70)
	Input.action_release("shoot")
	Input.action_release("move_up")
	_check(saw_truth, "Truth fires a bolt")
	_check(truth_pierce[0], "Truth bolt pierces")

	# Beat 2 and the second Shift: chain holds again.
	var got_beat_2: bool = await _earn_beat_from_rifleman(rifleman)
	_check(got_beat_2, "second roll-through earns a Beat")
	Input.action_press("shift")
	await _frames(3)
	Input.action_release("shift")
	_check(_player.form == LaForma.Form.FREEDOM, "Shift cycles Truth -> Freedom")
	_check(_player.chain == 2, "chain holds at 2")

	# Freedom fire: exactly 5 pellets and a burst of velocity.
	# Fired from a clear stretch of street so no pellet can land
	# the same tick it spawns.
	var drained: bool = await _wait_until(func() -> bool: return _player_bolts().size() == 0, 200)
	_check(drained, "bolt field drains before the Freedom shot")
	_player.global_position = Vector2(600.0, 536.0)
	_player.velocity = Vector2.ZERO
	Input.action_press("move_right")
	await _frames(2)
	Input.action_release("move_right")
	var pellet_max: int = 0
	var burst_vx: float = 0.0
	Input.action_press("shoot")
	for i: int in 4:
		await _frames(1)
		pellet_max = maxi(pellet_max, _player_bolts().size())
		burst_vx = maxf(burst_vx, _player.velocity.x)
	Input.action_release("shoot")
	_check(pellet_max == ScrollerPlayer.FREEDOM_PELLETS, "Freedom fires 5 pellets (saw %d)" % pellet_max)
	_check(burst_vx > 200.0, "Freedom shot bursts the player (vx=%.0f)" % burst_vx)

	# The duel.
	_level.start_duel()
	await _frames(5)
	_check(_level.boss != null and is_instance_valid(_level.boss), "framing agent spawns")
	_check(_level.gates_locked, "arena gates lock")
	_player.global_position = _boss_side_position()
	_player.velocity = Vector2.ZERO
	await _frames(2)

	# Two Beats off boss bolts, then two Shifts back to Truth.
	var boss_beats: bool = await _earn_beats_near_boss(2, 1500)
	_check(boss_beats, "two Beats earned in the duel (beats=%d)" % _player.beats)
	Input.action_press("shift")
	await _frames(3)
	Input.action_release("shift")
	_check(_player.form == LaForma.Form.VENGEANCE, "Shift cycles Freedom -> Vengeance")
	Input.action_press("shift")
	await _frames(3)
	Input.action_release("shift")
	_check(_player.form == LaForma.Form.TRUTH, "Shift cycles Vengeance -> Truth")

	# Truth marks the boss (x1), the next hit lands marked (x3).
	# Shots are retried from the boss's centre side until one
	# lands; the first landed hit is the marking hit by
	# construction, so its delta must be exactly x1.
	var mark_delta: int = 0
	for attempt: int in 4:
		var hp_try: int = _level.boss.hp
		if await _fire_at_boss_once():
			mark_delta = hp_try - _level.boss.hp
			break
	_check(mark_delta == ScrollerPlayer.TRUTH_DAMAGE, "marking hit deals x1 (%d)" % mark_delta)
	_check(_level.boss.is_marked(), "boss weak point marked")
	var marked_delta: int = 0
	for attempt: int in 4:
		var hp_try_2: int = _level.boss.hp
		if await _fire_at_boss_once():
			marked_delta = hp_try_2 - _level.boss.hp
			break
	_check(marked_delta == ScrollerPlayer.TRUTH_DAMAGE * ScrollerEnemy.MARK_DAMAGE_MULT, "marked hit deals x3 (%d)" % marked_delta)

	# Finish the boss through the real damage path bolts use.
	var guard: int = 0
	while is_instance_valid(_level.boss) and _level.boss.hp > 0 and guard < 40:
		_level.boss.take_bolt_hit(10, LaForma.Form.VENGEANCE, _level.boss.global_position)
		guard += 1
		await _frames(2)
	var cleared_ok: bool = await _wait_until(func() -> bool: return _level.cleared, 120)
	_check(cleared_ok, "boss defeat clears the Dusk shift")
	_check(not _level.gates_locked, "gates open after the duel")
	_check(_level.hud.is_clear_shown(), "clear screen shows the time")

	_release_all()
	print("SMOKE RESULT: %d checks, %d failures" % [_checks, _failures])
	quit(1 if _failures > 0 else 0)
