class_name Player
extends CharacterBody2D
## The Adler heir. Movement, La Forma combat, dodge/parry, Beats.
##
## Contract: the game drives input gating via input_enabled; combat
## numbers live here and in content.gd. Damage in arrives through
## projectile_hit() and melee_hit(); both respect the dodge state.
## Emits signals instead of reaching into the game (ownership: game
## listens, player never calls up).

signal beat_gained(total: int)
signal form_changed(form: int)
signal health_changed(hp: int, max_hp: int)
signal died
signal attacked

const MAX_HP: int = 100
const MAX_BEATS: int = 3
const SPEED_PX_S: float = 175.0
const FREEDOM_SPEED_MULT: float = 1.35
const DODGE_SPEED: float = 430.0
const DODGE_TIME_S: float = 0.30
const PARRY_WINDOW_S: float = 0.16
const SHIFT_COOLDOWN_S: float = 0.5
const MELEE_RANGE_PX: float = 62.0
const MELEE_DAMAGE: int = 6
const GATLING_TICK_S: float = 0.09
const GATLING_DAMAGE: int = 2
const RIFLE_DAMAGE: int = 22
const RIFLE_COOLDOWN_S: float = 0.45
const SCATTER_PELLETS: int = 5
const SCATTER_DAMAGE: int = 4
const COMBO_WINDOW_S: float = 0.9

var is_player: bool = true
var hp: int = MAX_HP
var beats: int = 1
var form: int = Content.FORM_VENGEANCE
var input_enabled: bool = false
## Test hook: the scripted playthrough scales outgoing damage so
## duels resolve in bounded time. Never set outside tests.
var test_damage_mult: float = 1.0

var _facing: Vector2 = Vector2.RIGHT
var _dodge_left_s: float = 0.0
var _dodge_dir: Vector2 = Vector2.RIGHT
var _parry_armed: bool = false
var _shift_cd_s: float = 0.0
var _rifle_cd_s: float = 0.0
var _gatling_acc_s: float = 0.0
var _combo_hits: int = 0
var _combo_left_s: float = 0.0
var _hurt_flash_s: float = 0.0

var figure: Figure
var game: Node  # set by game.gd; used only for projectile spawning + fx


func _ready() -> void:
	var shape: CollisionShape2D = CollisionShape2D.new()
	var capsule: CapsuleShape2D = CapsuleShape2D.new()
	capsule.radius = 12.0
	capsule.height = 44.0
	shape.shape = capsule
	shape.position = Vector2(0, -6)
	add_child(shape)
	figure = Figure.new()
	figure.build(Content.CHARACTERS["heir"])
	add_child(figure)
	figure.set_form(form)
	z_index = 10


func _physics_process(delta: float) -> void:
	_shift_cd_s = maxf(0.0, _shift_cd_s - delta)
	_rifle_cd_s = maxf(0.0, _rifle_cd_s - delta)
	_combo_left_s = maxf(0.0, _combo_left_s - delta)
	if _combo_left_s == 0.0:
		_combo_hits = 0
	if _hurt_flash_s > 0.0:
		_hurt_flash_s -= delta
		figure.modulate = Color(1.6, 0.7, 0.7) if _hurt_flash_s > 0.0 else Color.WHITE

	if not input_enabled:
		velocity = velocity.move_toward(Vector2.ZERO, 900.0 * delta)
		move_and_slide()
		return

	var move_vec: Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if _dodge_left_s > 0.0:
		_dodge_left_s -= delta
		velocity = _dodge_dir * DODGE_SPEED
		if _dodge_left_s <= 0.0:
			_parry_armed = false
	else:
		var speed: float = SPEED_PX_S
		if form == Content.FORM_FREEDOM:
			speed *= FREEDOM_SPEED_MULT
		velocity = move_vec * speed
		if move_vec != Vector2.ZERO:
			_facing = move_vec.normalized()
			figure.set_facing(move_vec.x)
			figure.walk_bob(move_vec.length() * speed * delta)
	if Input.is_action_just_pressed("dodge"):
		start_dodge(move_vec)
	if Input.is_action_just_pressed("shift"):
		shift_form((form + 1) % 3)
	if Input.is_action_just_pressed("form_1"):
		shift_form(Content.FORM_VENGEANCE)
	if Input.is_action_just_pressed("form_2"):
		shift_form(Content.FORM_TRUTH)
	if Input.is_action_just_pressed("form_3"):
		shift_form(Content.FORM_FREEDOM)
	_handle_attack(delta)
	move_and_slide()


## Begins a dodge in the input (or facing) direction. The first
## PARRY_WINDOW_S of the dodge is the parry window: a hit landing
## inside it is negated and earns a Beat.
func start_dodge(move_vec: Vector2) -> void:
	if _dodge_left_s > 0.0:
		return
	_dodge_dir = move_vec.normalized() if move_vec != Vector2.ZERO else _facing
	_dodge_left_s = DODGE_TIME_S
	_parry_armed = true
	if game != null and game.has_method("play_sfx"):
		game.play_sfx("dodge_whoosh")


## Spends a Beat to morph the Desperado. Returns false without a
## Beat or during cooldown; the kata never breaks on a refused shift.
func shift_form(target: int) -> bool:
	if target == form or _shift_cd_s > 0.0:
		return false
	if beats < 1:
		if game != null and game.has_method("play_sfx"):
			game.play_sfx("shift_denied")
		return false
	beats -= 1
	form = target
	_shift_cd_s = SHIFT_COOLDOWN_S
	_combo_hits = 0
	figure.set_form(form)
	if game != null:
		if game.has_method("on_player_shift"):
			game.on_player_shift(global_position, figure.silhouette(), _facing)
		if game.has_method("play_sfx"):
			game.play_sfx("shift_snap")
	beat_gained.emit(beats)
	form_changed.emit(form)
	return true


## Awards a Beat (parry, last-instant dodge). Capped at MAX_BEATS.
func gain_beat() -> void:
	if beats < MAX_BEATS:
		beats += 1
		beat_gained.emit(beats)


## True while a hit would be parried rather than taken.
func is_parry_active() -> bool:
	return _parry_armed and _dodge_left_s > DODGE_TIME_S - PARRY_WINDOW_S


## True while dodging (i-frames for projectile purposes).
func is_dodging() -> bool:
	return _dodge_left_s > 0.0


## Damage entry point (melee). Returns "parried", "dodged", or "hit".
func melee_hit(damage: int, _from_pos: Vector2) -> String:
	if is_parry_active():
		gain_beat()
		if game != null and game.has_method("on_parry"):
			game.on_parry()
		return "parried"
	if is_dodging():
		return "dodged"
	_apply_damage(damage)
	return "hit"


## Damage entry point (projectiles), called by projectile.gd.
func projectile_hit(damage: int, from_pos: Vector2, _form: int = -1) -> void:
	var result: String = melee_hit(damage, from_pos)
	if result == "parried" and game != null and game.has_method("play_sfx"):
		game.play_sfx("parry_chime")


func _apply_damage(damage: int) -> void:
	if hp <= 0:
		return
	hp = maxi(0, hp - damage)
	_hurt_flash_s = 0.18
	health_changed.emit(hp, MAX_HP)
	if game != null and game.has_method("play_sfx"):
		game.play_sfx("player_hurt")
	if hp == 0:
		died.emit()


## Full heal between passes (game calls at pass changes / retries).
func heal_full() -> void:
	hp = MAX_HP
	beats = maxi(beats, 1)
	health_changed.emit(hp, MAX_HP)
	beat_gained.emit(beats)


func _handle_attack(delta: float) -> void:
	match form:
		Content.FORM_VENGEANCE:
			if Input.is_action_just_pressed("attack"):
				_melee_combo_hit()
			if Input.is_action_pressed("attack"):
				_gatling_acc_s += delta
				while _gatling_acc_s >= GATLING_TICK_S:
					_gatling_acc_s -= GATLING_TICK_S
					_spawn_shot(560.0, GATLING_DAMAGE, 0.10)
			else:
				_gatling_acc_s = 0.0
		Content.FORM_TRUTH:
			if Input.is_action_just_pressed("attack") and _rifle_cd_s == 0.0:
				_rifle_cd_s = RIFLE_COOLDOWN_S
				_spawn_shot(820.0, RIFLE_DAMAGE, 0.0, true)
				if game != null and game.has_method("play_sfx"):
					game.play_sfx("rifle_shot")
		Content.FORM_FREEDOM:
			if Input.is_action_just_pressed("attack"):
				for i: int in SCATTER_PELLETS:
					var spread: float = lerpf(-0.32, 0.32, float(i) / float(SCATTER_PELLETS - 1))
					_spawn_shot(520.0, SCATTER_DAMAGE, spread)
				velocity += _facing * 190.0
				if game != null and game.has_method("play_sfx"):
					game.play_sfx("scatter_shot")
	attacked.emit()


func _melee_combo_hit() -> void:
	_combo_hits += 1
	_combo_left_s = COMBO_WINDOW_S
	if game != null and game.has_method("player_melee"):
		var dmg: int = int(round(float(MELEE_DAMAGE) * test_damage_mult))
		game.player_melee(global_position + _facing * MELEE_RANGE_PX * 0.6, MELEE_RANGE_PX, dmg, form)
	if game != null and game.has_method("play_sfx"):
		game.play_sfx("pistol_shot")


func _spawn_shot(speed: float, damage: int, spread_rad: float, pierce: bool = false) -> void:
	if game == null or not game.has_method("spawn_projectile"):
		return
	var dir: Vector2 = _facing.rotated(spread_rad)
	var dmg: int = int(round(float(damage) * test_damage_mult))
	game.spawn_projectile(global_position + dir * 26.0 + Vector2(0, -16), dir, speed, dmg, true, Content.FORM_COLORS[form], pierce)


## The facing direction (tests + game queries).
func facing() -> Vector2:
	return _facing


## Sets facing directly (dialogue staging, tests).
func face_toward(dir: Vector2) -> void:
	if dir != Vector2.ZERO:
		_facing = dir.normalized()
		figure.set_facing(dir.x)
