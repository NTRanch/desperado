class_name ScrollerPlayer
extends CharacterBody2D
## The Adler heir, scroller cut: run, jump, crouch, 8-way aim in
## Metal Slug grammar, and La Forma — last-instant play earns
## Beats, and Beats are spent to Shift the Desperado mid-combo
## (DESIGN.md).
## Contract: input is read only in this file. The verbs
## (start_dodge, perform_shift, earn_beat, and the per-form fire
## paths) are plain methods, so the input path and the headless
## smoke test drive the same code. Damage entry points return
## true when a hit is absorbed; during i-frames they return
## false and the caller (a bolt) flies on.

signal beats_changed
signal form_changed(form: int)
signal hp_changed
signal beat_earned
signal shifted(form: int)
signal died

const RUN_SPEED_PX_S: float = 260.0
const GRAVITY_PX_S2: float = 1400.0
const JUMP_VELOCITY_PX_S: float = -620.0
const DODGE_TIME_S: float = 0.28
const DODGE_SPEED_PX_S: float = 520.0
const POST_HIT_INVULN_S: float = 0.8
const RESPAWN_INVULN_S: float = 1.5
const MAX_HP: int = 10
const MAX_BEATS: int = 8
const BEAT_RADIUS_PX: float = 30.0
const CHARGE_BEAT_RADIUS_PX: float = 54.0
const CHAIN_WINDOW_S: float = 1.0
const VENGEANCE_INTERVAL_S: float = 0.16
const VENGEANCE_GATLING_MIN_INTERVAL_S: float = 0.055
const VENGEANCE_GATLING_RAMP_S: float = 1.2
const GATLING_CHAIN_MIN: int = 4
const VENGEANCE_DAMAGE: int = 1
const VENGEANCE_BOLT_SPEED_PX_S: float = 900.0
const TRUTH_INTERVAL_S: float = 0.55
const TRUTH_DAMAGE: int = 3
const TRUTH_BOLT_SPEED_PX_S: float = 1250.0
const FREEDOM_INTERVAL_S: float = 0.34
const FREEDOM_PELLETS: int = 5
const FREEDOM_SPREAD_DEG: float = 11.0
const FREEDOM_DAMAGE: int = 1
const FREEDOM_BOLT_SPEED_PX_S: float = 850.0
const FREEDOM_BURST_IMPULSE_PX_S: float = 470.0
const FREEDOM_BURST_CONTROL_S: float = 0.22
const FREEDOM_BURST_INVULN_S: float = 0.18
const BURST_STEER_PX_S2: float = 2600.0
const GUN_LENGTHS: Array = [22.0, 36.0, 26.0]
const STAND_SIZE: Vector2 = Vector2(24.0, 48.0)
const CROUCH_SIZE: Vector2 = Vector2(26.0, 30.0)
const LAYER_PLAYER: int = 2
const MASK_WORLD: int = 1

var form: int = LaForma.Form.VENGEANCE
var beats: int = 0
var chain: int = 0
var hp: int = MAX_HP
var facing: int = 1
var is_player: bool = true

var _aim: Vector2 = Vector2.RIGHT
var _crouching: bool = false
var _fire_cooldown_s: float = 0.0
var _trigger_held_s: float = 0.0
var _dodge_s: float = 0.0
var _dodge_dir: int = 1
var _invuln_s: float = 0.0
var _burst_s: float = 0.0
var _since_beat_s: float = 999.0
var _age_s: float = 0.0

var _shape_node: CollisionShape2D
var _stand_shape: RectangleShape2D
var _crouch_shape: RectangleShape2D
var _figure: Node2D
var _arm: Node2D
var _gun: Polygon2D
var _gun_tip: Polygon2D


func _ready() -> void:
	add_to_group("player")
	collision_layer = LAYER_PLAYER
	collision_mask = MASK_WORLD
	_stand_shape = RectangleShape2D.new()
	_stand_shape.size = STAND_SIZE
	_crouch_shape = RectangleShape2D.new()
	_crouch_shape.size = CROUCH_SIZE
	_shape_node = CollisionShape2D.new()
	_shape_node.shape = _stand_shape
	add_child(_shape_node)
	_build_figure()
	_update_gun_shape()


## True during the dodge roll (the Beat window).
func is_dodging() -> bool:
	return _dodge_s > 0.0


## True while any i-frames are live (dodge, burst, post-hit grace).
func is_invulnerable() -> bool:
	return _dodge_s > 0.0 or _invuln_s > 0.0


## Starts the dodge roll in the input direction (or facing).
## Grounded only; the roll is the Beat instrument — bolts that
## pass within BEAT_RADIUS_PX during it pay out via the scan.
func start_dodge(input_dir: float) -> void:
	if _dodge_s > 0.0 or not is_on_floor():
		return
	if input_dir != 0.0:
		_dodge_dir = 1 if input_dir > 0.0 else -1
	else:
		_dodge_dir = facing
	_dodge_s = DODGE_TIME_S
	_crouching = false
	_scan_beats()


## Spends one Beat to morph the Desperado to the next form.
## Shifted within CHAIN_WINDOW_S of the last Beat earned, the
## chain grows (the kata holds); later, the chain resets to 0
## before the morph (the kata breaks). No Beat, no Shift.
func perform_shift() -> void:
	if beats <= 0:
		return
	beats -= 1
	if _since_beat_s <= CHAIN_WINDOW_S:
		chain += 1
	else:
		chain = 0
	form = LaForma.next_form(form)
	_update_gun_shape()
	beats_changed.emit()
	form_changed.emit(form)
	shifted.emit(form)


## Pays one Beat (dodge scan, shot-down bolt, boss charge).
## At the cap the pip count holds but the chain window refreshes.
func earn_beat() -> void:
	_since_beat_s = 0.0
	if beats < MAX_BEATS:
		beats += 1
		beats_changed.emit()
	beat_earned.emit()


## Pays several Beats at once (the Deseo cache payout).
func add_beats(count: int) -> void:
	for i: int in count:
		earn_beat()


## Bolt entry point: invulnerable targets refuse the hit (the
## bolt flies on); anything else flows into take_damage().
func take_bolt_hit(damage_value: int, _hit_form: int, from_pos: Vector2) -> bool:
	if is_invulnerable():
		return false
	return take_damage(damage_value, from_pos)


## The one damage path. Returns true when the hit is absorbed.
func take_damage(damage_value: int, _from_pos: Vector2) -> bool:
	if is_invulnerable():
		return false
	hp -= damage_value
	_invuln_s = POST_HIT_INVULN_S
	hp_changed.emit()
	if hp <= 0:
		died.emit()
	return true


## Restores the player at a street position (level's respawn).
func respawn(at: Vector2) -> void:
	global_position = at
	velocity = Vector2.ZERO
	hp = MAX_HP
	_dodge_s = 0.0
	_burst_s = 0.0
	_invuln_s = RESPAWN_INVULN_S
	hp_changed.emit()


func _physics_process(delta: float) -> void:
	_tick(delta)
	var input_dir: float = Input.get_axis("move_left", "move_right")
	if input_dir != 0.0:
		facing = 1 if input_dir > 0.0 else -1
	_crouching = is_on_floor() and _dodge_s <= 0.0 and Input.is_action_pressed("crouch")
	_apply_crouch_shape()
	_update_aim(input_dir)
	if is_on_floor():
		velocity.y = 1.0
	else:
		velocity.y += GRAVITY_PX_S2 * delta
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY_PX_S
		_crouching = false
	if Input.is_action_just_pressed("dodge"):
		start_dodge(input_dir)
	if Input.is_action_just_pressed("shift"):
		perform_shift()
	if _dodge_s > 0.0:
		velocity.x = float(_dodge_dir) * DODGE_SPEED_PX_S
		_scan_beats()
	elif _burst_s > 0.0:
		var target: float = 0.0 if _crouching else input_dir * RUN_SPEED_PX_S
		velocity.x = move_toward(velocity.x, target, BURST_STEER_PX_S2 * delta)
	elif _crouching:
		velocity.x = 0.0
	else:
		velocity.x = input_dir * RUN_SPEED_PX_S
	_handle_fire(delta)
	move_and_slide()
	_update_figure()


func _tick(delta: float) -> void:
	_age_s += delta
	_since_beat_s = minf(_since_beat_s + delta, 999.0)
	_invuln_s = maxf(0.0, _invuln_s - delta)
	_burst_s = maxf(0.0, _burst_s - delta)
	_fire_cooldown_s = maxf(0.0, _fire_cooldown_s - delta)
	if _dodge_s > 0.0:
		_dodge_s = maxf(0.0, _dodge_s - delta)


func _update_aim(input_dir: float) -> void:
	if _crouching:
		_aim = Vector2(float(facing), 0.0)
		return
	var up: bool = Input.is_action_pressed("move_up")
	var down: bool = Input.is_action_pressed("move_down")
	if up:
		if input_dir != 0.0:
			_aim = Vector2(float(facing), -1.0).normalized()
		else:
			_aim = Vector2.UP
	elif down and not is_on_floor():
		if input_dir != 0.0:
			_aim = Vector2(float(facing), 1.0).normalized()
		else:
			_aim = Vector2.DOWN
	else:
		_aim = Vector2(float(facing), 0.0)


func _scan_beats() -> void:
	for node: Node in get_tree().get_nodes_in_group("enemy_bolts"):
		var bolt: ScrollerBolt = node as ScrollerBolt
		if bolt == null or bolt.beat_counted:
			continue
		if global_position.distance_to(bolt.global_position) <= BEAT_RADIUS_PX:
			bolt.beat_counted = true
			earn_beat()
	var agent: Node = get_tree().get_first_node_in_group("framing_agent")
	if agent != null and bool(agent.get("charging")) and not bool(agent.get("charge_beat_counted")):
		if global_position.distance_to(agent.global_position) <= CHARGE_BEAT_RADIUS_PX:
			agent.set("charge_beat_counted", true)
			earn_beat()


func _handle_fire(delta: float) -> void:
	if Input.is_action_pressed("shoot"):
		_trigger_held_s += delta
	else:
		_trigger_held_s = 0.0
	if _dodge_s > 0.0:
		return
	if not Input.is_action_pressed("shoot") or _fire_cooldown_s > 0.0:
		return
	match form:
		LaForma.Form.VENGEANCE:
			_fire_vengeance()
		LaForma.Form.TRUTH:
			_fire_truth()
		LaForma.Form.FREEDOM:
			_fire_freedom()


func _fire_vengeance() -> void:
	_spawn_bolt(_aim, VENGEANCE_BOLT_SPEED_PX_S, VENGEANCE_DAMAGE, false)
	var interval: float = VENGEANCE_INTERVAL_S
	if chain >= GATLING_CHAIN_MIN:
		var t: float = clampf(_trigger_held_s / VENGEANCE_GATLING_RAMP_S, 0.0, 1.0)
		interval = lerpf(VENGEANCE_INTERVAL_S, VENGEANCE_GATLING_MIN_INTERVAL_S, t)
	_fire_cooldown_s = interval


func _fire_truth() -> void:
	_spawn_bolt(_aim, TRUTH_BOLT_SPEED_PX_S, TRUTH_DAMAGE, true)
	_fire_cooldown_s = TRUTH_INTERVAL_S


func _fire_freedom() -> void:
	var mid: float = float(FREEDOM_PELLETS - 1) * 0.5
	for i: int in FREEDOM_PELLETS:
		var dir: Vector2 = _aim.rotated(deg_to_rad((float(i) - mid) * FREEDOM_SPREAD_DEG))
		_spawn_bolt(dir, FREEDOM_BOLT_SPEED_PX_S, FREEDOM_DAMAGE, false)
	velocity += _aim * FREEDOM_BURST_IMPULSE_PX_S
	if is_on_floor() and velocity.y > 0.0:
		velocity.y = 0.0
	_burst_s = FREEDOM_BURST_CONTROL_S
	_invuln_s = maxf(_invuln_s, FREEDOM_BURST_INVULN_S)
	_fire_cooldown_s = FREEDOM_INTERVAL_S


func _spawn_bolt(dir: Vector2, speed_px_s: float, damage_value: int, pierce: bool) -> void:
	var bolt: ScrollerBolt = ScrollerBolt.new()
	get_parent().add_child(bolt)
	bolt.fire(_muzzle_position(), dir, speed_px_s, damage_value, true, form, LaForma.color_of(form), pierce, self)


func _muzzle_position() -> Vector2:
	return global_position + _aim * 26.0 + Vector2(0.0, -4.0)


func _apply_crouch_shape() -> void:
	var want: RectangleShape2D = _crouch_shape if _crouching else _stand_shape
	if _shape_node.shape != want:
		_shape_node.shape = want
		_shape_node.position = Vector2(0.0, 9.0) if _crouching else Vector2.ZERO


func _update_gun_shape() -> void:
	var length: float = float(GUN_LENGTHS[form])
	_gun.polygon = PackedVector2Array([
		Vector2(0.0, -3.0), Vector2(length, -1.5), Vector2(length, 1.5), Vector2(0.0, 3.0),
	])
	_gun_tip.position = Vector2(length + 2.0, 0.0)
	_gun_tip.color = LaForma.color_of(form)


func _update_figure() -> void:
	_figure.scale.x = float(facing)
	var local_dir: Vector2 = Vector2(_aim.x * float(facing), _aim.y)
	_arm.rotation = local_dir.angle()
	_figure.position.y = 7.0 if _crouching else 0.0
	if _invuln_s > 0.0 and _dodge_s <= 0.0:
		_figure.modulate.a = 0.6 + 0.4 * sin(_age_s * 30.0)
	else:
		_figure.modulate.a = 1.0


func _build_figure() -> void:
	_figure = Node2D.new()
	add_child(_figure)
	var legs: Polygon2D = Polygon2D.new()
	legs.polygon = DrawUtil.rect_points(18.0, 16.0)
	legs.position = Vector2(0.0, 16.0)
	legs.color = Color(0.16, 0.14, 0.2)
	_figure.add_child(legs)
	var coat: Polygon2D = Polygon2D.new()
	coat.polygon = DrawUtil.rect_points(22.0, 25.0)
	coat.position = Vector2(0.0, -2.0)
	coat.color = Color(0.1, 0.45, 0.5)
	_figure.add_child(coat)
	var scarf: Polygon2D = Polygon2D.new()
	scarf.polygon = DrawUtil.rect_points(16.0, 5.0)
	scarf.position = Vector2(0.0, -13.0)
	scarf.color = Color(0.95, 0.65, 0.2)
	_figure.add_child(scarf)
	var head: Polygon2D = Polygon2D.new()
	head.polygon = DrawUtil.circle_points(7.5)
	head.position = Vector2(0.0, -21.0)
	head.color = Color(0.88, 0.68, 0.53)
	_figure.add_child(head)
	var hair: Polygon2D = Polygon2D.new()
	hair.polygon = PackedVector2Array([
		Vector2(-8.0, -24.0), Vector2(8.0, -24.0), Vector2(7.0, -29.0), Vector2(-7.0, -29.0),
	])
	hair.color = Color(0.2, 0.12, 0.1)
	_figure.add_child(hair)
	_arm = Node2D.new()
	_arm.position = Vector2(2.0, -8.0)
	_figure.add_child(_arm)
	_gun = Polygon2D.new()
	_gun.color = Color(0.14, 0.13, 0.16)
	_arm.add_child(_gun)
	_gun_tip = Polygon2D.new()
	_gun_tip.polygon = DrawUtil.rect_points(5.0, 4.0)
	_arm.add_child(_gun_tip)
