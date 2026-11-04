class_name Duelist
extends CharacterBody2D
## A duel opponent: telegraphed attacks, pattern table from
## content.gd, optional boss phases that answer one morph and
## punish another.
##
## Contract: the game arms the duelist with arm(def, target) and
## reads the outcome via signals (defeated / surrendered /
## phase_changed). Attacks announce themselves: WINDUP flashes the
## gun for windup_s before STRIKE resolves — that window is where
## the player's last-instant dodge lives. Emits attack_whiffed when
## a strike connects with nothing (the game may award a Beat for a
## last-instant dodge).

signal defeated(duelist: Duelist)
signal surrendered(duelist: Duelist)
signal phase_changed(phase: int)
signal attack_whiffed(duelist: Duelist)

const STATE_IDLE: int = 0
const STATE_APPROACH: int = 1
const STATE_WINDUP: int = 2
const STATE_STRIKE: int = 3
const STATE_RECOVER: int = 4
const STATE_STAGGERED: int = 5
const STATE_DONE: int = 6

const MELEE_REACH_PX: float = 74.0
const PREFERRED_RANGE_PX: float = 250.0
const STAGGER_S: float = 0.9
const WEAK_POINT_BONUS: float = 2.2
const WEAK_POINT_WINDOW_S: float = 3.0

var is_player: bool = false
var duelist_id: String = ""
var hp: int = 0
var max_hp: int = 0
var active: bool = false
## Set by the game while the player parries this duelist's kin:
## Truth shots inside the window deal WEAK_POINT_BONUS damage.
var weak_point_left_s: float = 0.0

var _def: Dictionary = {}
var _target: Player
var _state: int = STATE_IDLE
var _state_left_s: float = 0.0
var _pattern_idx: int = 0
var _phase: int = 0
var _phase_thresholds: Array[int] = []
var _facing: Vector2 = Vector2.LEFT
var _hurt_flash_s: float = 0.0

var figure: Figure
var game: Node


func _ready() -> void:
	var shape: CollisionShape2D = CollisionShape2D.new()
	var capsule: CapsuleShape2D = CapsuleShape2D.new()
	capsule.radius = 12.0
	capsule.height = 44.0
	shape.shape = capsule
	shape.position = Vector2(0, -6)
	add_child(shape)
	figure = Figure.new()
	add_child(figure)
	z_index = 10
	set_physics_process(false)


## Arms the duelist for a fight. character_id selects the figure.
func arm(def: Dictionary, character_id: String, target: Player) -> void:
	_def = def
	_target = target
	duelist_id = character_id
	max_hp = int(def["hp"])
	hp = max_hp
	_phase = 0
	_pattern_idx = 0
	_phase_thresholds.clear()
	if def.has("phases"):
		var phases: Array = def["phases"]
		for i: int in phases.size() - 1:
			_phase_thresholds.append(int(round(float(max_hp) * float(phases.size() - 1 - i) / float(phases.size()))))
	figure.build(Content.CHARACTERS[character_id])
	figure.set_sidearm()
	active = true
	_state = STATE_APPROACH
	set_physics_process(true)


## Disarms (duel over / not yet begun).
func disarm() -> void:
	active = false
	_state = STATE_IDLE
	set_physics_process(false)
	velocity = Vector2.ZERO


func _physics_process(delta: float) -> void:
	if not active or _target == null or not is_instance_valid(_target):
		return
	weak_point_left_s = maxf(0.0, weak_point_left_s - delta)
	if _hurt_flash_s > 0.0:
		_hurt_flash_s -= delta
		figure.modulate = Color(1.7, 0.8, 0.8) if _hurt_flash_s > 0.0 else Color.WHITE
	_state_left_s -= delta
	var to_target: Vector2 = _target.global_position - global_position
	var dist: float = to_target.length()
	if dist > 1.0:
		_facing = to_target.normalized()
		figure.set_facing(_facing.x)
	match _state:
		STATE_APPROACH:
			_approach(to_target, dist)
			if _state_left_s <= 0.0:
				_begin_windup()
		STATE_WINDUP:
			velocity = Vector2.ZERO
			if _state_left_s <= 0.0:
				_strike(to_target, dist)
		STATE_STRIKE, STATE_RECOVER, STATE_STAGGERED:
			velocity = velocity.move_toward(Vector2.ZERO, 800.0 * delta)
			if _state_left_s <= 0.0:
				_state = STATE_APPROACH
				_state_left_s = randf_range(0.25, 0.6)
		_:
			velocity = Vector2.ZERO
	move_and_slide()


func _approach(to_target: Vector2, dist: float) -> void:
	var pattern: String = _current_pattern()
	var speed: float = float(_def["speed"])
	if pattern == "shot" or pattern == "burst":
		if dist > PREFERRED_RANGE_PX:
			velocity = to_target.normalized() * speed
			figure.walk_bob(speed * get_physics_process_delta_time())
		elif dist < PREFERRED_RANGE_PX * 0.6:
			velocity = -to_target.normalized() * speed * 0.7
		else:
			velocity = Vector2.ZERO
	else:
		if dist > MELEE_REACH_PX * 0.8:
			velocity = to_target.normalized() * speed
			figure.walk_bob(speed * get_physics_process_delta_time())
		else:
			velocity = Vector2.ZERO


func _current_pattern() -> String:
	var patterns: Array = _def["patterns"]
	if patterns.is_empty():
		return "melee"
	return String(patterns[_pattern_idx % patterns.size()])


func _begin_windup() -> void:
	_state = STATE_WINDUP
	_state_left_s = float(_def["windup_s"])
	figure.modulate = Color(1.5, 1.3, 0.6)
	if game != null and game.has_method("play_sfx"):
		game.play_sfx("enemy_windup")


func _strike(to_target: Vector2, dist: float) -> void:
	figure.modulate = Color.WHITE
	var pattern: String = _current_pattern()
	_pattern_idx += 1
	var connected: bool = false
	match pattern:
		"melee":
			if dist <= MELEE_REACH_PX + 26.0 and _target != null:
				var result: String = _target.melee_hit(int(_def["melee_damage"]), global_position)
				connected = result != "dodged"
				if result == "parried":
					_stagger()
					return
			velocity = _facing * 260.0
		"dash":
			velocity = _facing * 520.0
			if dist <= MELEE_REACH_PX + 60.0 and _target != null:
				var result: String = _target.melee_hit(int(_def["melee_damage"]), global_position)
				connected = result != "dodged"
				if result == "parried":
					_stagger()
					return
		"shot":
			_fire_shot(1, 0.0)
			connected = true
		"burst":
			for i: int in 3:
				_fire_shot(1, lerpf(-0.09, 0.09, float(i) / 2.0))
			connected = true
		"feint":
			velocity = -_facing * 300.0
			_fire_shot(1, 0.14)
			connected = true
	if not connected and _target != null and _target.is_dodging():
		attack_whiffed.emit(self)
	_state = STATE_RECOVER
	_state_left_s = randf_range(0.45, 0.8)


func _fire_shot(count: int, spread_rad: float) -> void:
	if game == null or not game.has_method("spawn_projectile"):
		return
	for i: int in count:
		var dir: Vector2 = _facing.rotated(spread_rad)
		game.spawn_projectile(global_position + dir * 26.0 + Vector2(0, -16), dir, 430.0, int(_def["ranged_damage"]), false, Color(0.98, 0.75, 0.45), false)
	if game.has_method("play_sfx"):
		game.play_sfx("enemy_shot")


func _stagger() -> void:
	_state = STATE_STAGGERED
	_state_left_s = STAGGER_S
	weak_point_left_s = WEAK_POINT_WINDOW_S
	velocity = -_facing * 120.0


## Damage entry point (player projectiles). form is the shooter's
## La Forma form, carried by the projectile itself.
func projectile_hit(damage: int, _from_pos: Vector2, form: int = -1) -> void:
	take_hit(damage, form)


## Builds the figure without arming (town dressing before a duel).
func preview(character_id: String) -> void:
	figure.build(Content.CHARACTERS[character_id])
	figure.set_sidearm()


## Parry stagger applied from outside (projectile parries route
## here via the game; melee parries stagger inside _strike).
func apply_parry_stagger() -> void:
	if active:
		_stagger()


## Damage entry point (player melee + form-aware effects).
## form: the player's current form, for boss phase answers.
func take_hit(damage: int, form: int) -> void:
	if not active or hp <= 0:
		return
	var dealt: int = damage
	if form == Content.FORM_TRUTH and weak_point_left_s > 0.0:
		dealt = int(round(float(dealt) * WEAK_POINT_BONUS))
	if _def.has("phases"):
		var phases: Array = _def["phases"]
		var phase_def: Dictionary = phases[_phase]
		if form == int(phase_def["answer_form"]):
			dealt = int(round(float(dealt) * 1.6))
		elif form == int(phase_def["punished_form"]):
			dealt = int(round(float(dealt) * 0.35))
	hp = maxi(0, hp - dealt)
	_hurt_flash_s = 0.15
	if game != null and game.has_method("play_sfx"):
		game.play_sfx("hit_tick")
	var surrender_hp: int = int(_def.get("surrender_hp", 0))
	if surrender_hp > 0 and hp <= surrender_hp and hp > 0:
		hp = surrender_hp
		_finish(true)
		return
	if hp == 0:
		_finish(false)
		return
	if _def.has("phases") and _phase < _phase_thresholds.size():
		if hp <= _phase_thresholds[_phase]:
			_phase += 1
			_stagger()
			phase_changed.emit(_phase)
			if game != null and game.has_method("on_boss_phase"):
				game.on_boss_phase(_phase, global_position, figure.silhouette(), _facing)


func _finish(surrender: bool) -> void:
	active = false
	_state = STATE_DONE
	set_physics_process(false)
	velocity = Vector2.ZERO
	if surrender:
		surrendered.emit(self)
	else:
		defeated.emit(self)


## Current boss phase (0-based); -1 when not a boss.
func phase() -> int:
	if not _def.has("phases"):
		return -1
	return _phase
