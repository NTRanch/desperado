class_name FramingAgent
extends ScrollerEnemy
## The framing agent — the Dusk duel's mini-boss. Cycles three
## patterns with a pause between: an aimed 3-round volley of
## parryable bolts, a 5-way spread, and a charge the player must
## dodge. Its weak point is markable by Truth (base class).
## Contract: pattern order is fixed (volley, spread, charge) so
## the duel teaches its own rhythm. Rolling through the charge
## pays a Beat like rolling through a bolt: the player's dodge
## scan reads charging / charge_beat_counted (once per charge).

const AGENT_HP: int = 60
const BOLT_SPEED_PX_S: float = 460.0
const SPREAD_SPEED_PX_S: float = 400.0
const BOLT_DAMAGE: int = 1
const CHARGE_DAMAGE: int = 2
const IDLE_S: float = 0.7
const VOLLEY_COUNT: int = 3
const VOLLEY_GAP_S: float = 0.18
const SPREAD_COUNT: int = 5
const SPREAD_STEP_DEG: float = 15.0
const CHARGE_TELEGRAPH_S: float = 0.5
const CHARGE_SPEED_PX_S: float = 640.0
const CHARGE_MAX_S: float = 0.6
const CHARGE_CONTACT_PX: float = 50.0
const CHARGE_HEIGHT_BAND_PX: float = 64.0
const STALK_SPEED_PX_S: float = 45.0
const STALK_RANGE_PX: float = 320.0
const BODY_W: float = 40.0
const BODY_H: float = 76.0
const COAT_COLOR: Color = Color(0.32, 0.18, 0.48)
const COAT_HOT_COLOR: Color = Color(0.85, 0.25, 0.3)

enum State { IDLE, FIRING, CHARGE_TELEGRAPH, CHARGE }
enum Pattern { VOLLEY, SPREAD, CHARGE }

## True during the charge dash; read by the player's dodge scan.
var charging: bool = false
## Set by the player's dodge scan once the charge has paid a Beat.
var charge_beat_counted: bool = false
## Arena bounds in world x; the level sets these at spawn.
var arena_min_x: float = 0.0
var arena_max_x: float = 4800.0

var _state: int = State.IDLE
var _state_s: float = 0.0
var _pattern: int = Pattern.VOLLEY
var _shots_left: int = 0
var _shot_s: float = 0.0
var _charge_dir: int = 1
var _charge_hit_done: bool = false
var _facing: int = -1
var _coat: Polygon2D
var _arm: Node2D
var _muzzle: Marker2D


func _ready() -> void:
	super._ready()
	add_to_group("framing_agent")
	max_hp = AGENT_HP
	hp = AGENT_HP
	pop_color = Color(0.6, 0.35, 0.95)
	setup_body(BODY_W, BODY_H)
	_build_figure()


func act(delta: float) -> void:
	_state_s += delta
	if not is_instance_valid(player):
		velocity.x = 0.0
		return
	var to_player: Vector2 = player.global_position - global_position
	if _state != State.CHARGE and absf(to_player.x) > 2.0:
		_facing = 1 if to_player.x > 0.0 else -1
	_figure.scale.x = float(_facing)
	_aim_arm(to_player)
	match _state:
		State.IDLE:
			if absf(to_player.x) > STALK_RANGE_PX:
				velocity.x = float(_facing) * STALK_SPEED_PX_S
			else:
				velocity.x = 0.0
			if _state_s >= IDLE_S:
				_start_pattern()
		State.FIRING:
			velocity.x = 0.0
			_shot_s += delta
			if _shots_left > 0 and _shot_s >= VOLLEY_GAP_S:
				_shot_s = 0.0
				_shots_left -= 1
				_fire_bolt((player.global_position - _muzzle.global_position).normalized(), BOLT_SPEED_PX_S)
			if _shots_left <= 0:
				_advance_pattern()
		State.CHARGE_TELEGRAPH:
			velocity.x = 0.0
			var t: float = clampf(_state_s / CHARGE_TELEGRAPH_S, 0.0, 1.0)
			_coat.color = COAT_COLOR.lerp(COAT_HOT_COLOR, t)
			if _state_s >= CHARGE_TELEGRAPH_S:
				_coat.color = COAT_COLOR
				_charge_dir = _facing
				charging = true
				charge_beat_counted = false
				_charge_hit_done = false
				_set_state(State.CHARGE)
		State.CHARGE:
			velocity.x = float(_charge_dir) * CHARGE_SPEED_PX_S
			_check_charge_contact(to_player)
			if _state_s >= CHARGE_MAX_S or global_position.x <= arena_min_x or global_position.x >= arena_max_x:
				charging = false
				_advance_pattern()


func _start_pattern() -> void:
	match _pattern:
		Pattern.VOLLEY:
			_shots_left = VOLLEY_COUNT
			_shot_s = VOLLEY_GAP_S  # first round leaves immediately
			_set_state(State.FIRING)
		Pattern.SPREAD:
			_fire_spread()
			_advance_pattern()
		Pattern.CHARGE:
			_set_state(State.CHARGE_TELEGRAPH)


func _advance_pattern() -> void:
	_pattern = (_pattern + 1) % 3
	_set_state(State.IDLE)


func _set_state(next: int) -> void:
	_state = next
	_state_s = 0.0


func _check_charge_contact(to_player: Vector2) -> void:
	if _charge_hit_done:
		return
	if absf(to_player.x) <= CHARGE_CONTACT_PX and absf(to_player.y) <= CHARGE_HEIGHT_BAND_PX:
		_charge_hit_done = true
		if player.has_method("take_damage"):
			player.call("take_damage", CHARGE_DAMAGE, global_position)


func _fire_spread() -> void:
	var base_dir: Vector2 = Vector2(float(_facing), 0.0)
	var mid: float = float(SPREAD_COUNT - 1) * 0.5
	for i: int in SPREAD_COUNT:
		var dir: Vector2 = base_dir.rotated(deg_to_rad((float(i) - mid) * SPREAD_STEP_DEG))
		_fire_bolt(dir, SPREAD_SPEED_PX_S)


func _fire_bolt(direction: Vector2, speed_px_s: float) -> void:
	var bolt: ScrollerBolt = ScrollerBolt.new()
	get_parent().add_child(bolt)
	bolt.fire(_muzzle.global_position, direction, speed_px_s, BOLT_DAMAGE, false, -1, Color(1.0, 0.5, 0.35), false, self)


func _aim_arm(to_player: Vector2) -> void:
	var local_dir: Vector2 = Vector2(to_player.x * float(_facing), to_player.y)
	_arm.rotation = local_dir.angle()


func _build_figure() -> void:
	var legs: Polygon2D = Polygon2D.new()
	legs.polygon = DrawUtil.rect_points(26.0, 26.0)
	legs.position = Vector2(0.0, 25.0)
	legs.color = Color(0.12, 0.1, 0.16)
	_figure.add_child(legs)
	_coat = Polygon2D.new()
	_coat.polygon = DrawUtil.rect_points(34.0, 38.0)
	_coat.position = Vector2(0.0, -6.0)
	_coat.color = COAT_COLOR
	_figure.add_child(_coat)
	var core: Polygon2D = Polygon2D.new()
	core.polygon = DrawUtil.circle_points(6.0)
	core.position = Vector2(0.0, -4.0)
	core.color = Color(1.0, 0.7, 0.2)
	_figure.add_child(core)
	var head: Polygon2D = Polygon2D.new()
	head.polygon = DrawUtil.circle_points(9.0)
	head.position = Vector2(0.0, -33.0)
	head.color = Color(0.85, 0.64, 0.5)
	_figure.add_child(head)
	var hat: Polygon2D = Polygon2D.new()
	hat.polygon = PackedVector2Array([
		Vector2(-13.0, -40.0), Vector2(13.0, -40.0), Vector2(9.0, -52.0), Vector2(-9.0, -52.0),
	])
	hat.color = Color(0.1, 0.08, 0.14)
	_figure.add_child(hat)
	_arm = Node2D.new()
	_arm.position = Vector2(4.0, -14.0)
	_figure.add_child(_arm)
	var gun: Polygon2D = Polygon2D.new()
	gun.polygon = PackedVector2Array([
		Vector2(0.0, -2.5), Vector2(30.0, -1.0), Vector2(30.0, 2.0), Vector2(0.0, 3.5),
	])
	gun.color = Color(0.14, 0.12, 0.16)
	_arm.add_child(gun)
	_muzzle = Marker2D.new()
	_muzzle.position = Vector2(32.0, 0.0)
	_arm.add_child(_muzzle)
