class_name ScrollerRifleman
extends ScrollerEnemy
## Combine rifleman: a posted gun that telegraphs its aim, fires
## one parryable bolt at the player's position, cools down, and
## every few seconds repositions a short step along its post.
## Contract: fire_at() is the only firing path — the AI calls it,
## and tests can rely on it. Bolts are deliberately slow
## (BOLT_SPEED_PX_S) so a roll through them earns Beats.

const BOLT_SPEED_PX_S: float = 420.0
const BOLT_DAMAGE: int = 1
const TELEGRAPH_S: float = 0.6
const COOLDOWN_S: float = 1.5
const REPOSITION_EVERY_S: float = 4.0
const REPOSITION_STEP_PX: float = 110.0
const WALK_SPEED_PX_S: float = 60.0
const RANGE_PX: float = 640.0
const HEIGHT_BAND_PX: float = 130.0
const BODY_W: float = 26.0
const BODY_H: float = 46.0
const RIFLEMAN_HP: int = 6
const GUN_REST_COLOR: Color = Color(0.16, 0.14, 0.17)
const GUN_HOT_COLOR: Color = Color(1.0, 0.55, 0.2)

enum State { IDLE, TELEGRAPH, COOLDOWN, REPOSITION }

var _state: int = State.IDLE
var _state_s: float = 0.0
var _idle_s: float = 0.0
var _facing: int = 1
var _anchor_x: float = 0.0
var _target_x: float = 0.0
var _reposition_sign: int = 1
var _arm: Node2D
var _gun: Polygon2D
var _muzzle: Marker2D


func _ready() -> void:
	super._ready()
	max_hp = RIFLEMAN_HP
	hp = RIFLEMAN_HP
	pop_color = Color(0.85, 0.4, 0.25)
	setup_body(BODY_W, BODY_H)
	_anchor_x = global_position.x
	_target_x = _anchor_x
	_build_figure()


## Fires one bolt from the muzzle toward the target position.
func fire_at(target_pos: Vector2) -> void:
	var bolt: ScrollerBolt = ScrollerBolt.new()
	get_parent().add_child(bolt)
	var origin: Vector2 = _muzzle.global_position
	bolt.fire(origin, target_pos - origin, BOLT_SPEED_PX_S, BOLT_DAMAGE, false, -1, Color(1.0, 0.62, 0.3), false, self)


func act(delta: float) -> void:
	_state_s += delta
	if not is_instance_valid(player):
		velocity.x = 0.0
		return
	var to_player: Vector2 = player.global_position - global_position
	if absf(to_player.x) > 2.0:
		_facing = 1 if to_player.x > 0.0 else -1
	_figure.scale.x = float(_facing)
	_aim_arm(to_player)
	match _state:
		State.IDLE:
			velocity.x = 0.0
			_idle_s += delta
			if absf(to_player.x) <= RANGE_PX and absf(to_player.y) <= HEIGHT_BAND_PX:
				_set_state(State.TELEGRAPH)
			elif _idle_s >= REPOSITION_EVERY_S:
				_reposition_sign = -_reposition_sign
				_target_x = _anchor_x + float(_reposition_sign) * REPOSITION_STEP_PX
				_set_state(State.REPOSITION)
		State.TELEGRAPH:
			velocity.x = 0.0
			var t: float = clampf(_state_s / TELEGRAPH_S, 0.0, 1.0)
			_gun.color = GUN_REST_COLOR.lerp(GUN_HOT_COLOR, t)
			if _state_s >= TELEGRAPH_S:
				fire_at(player.global_position)
				_gun.color = GUN_REST_COLOR
				_set_state(State.COOLDOWN)
		State.COOLDOWN:
			velocity.x = 0.0
			if _state_s >= COOLDOWN_S:
				_idle_s = 0.0
				_set_state(State.IDLE)
		State.REPOSITION:
			var dx: float = _target_x - global_position.x
			if absf(dx) <= 4.0:
				velocity.x = 0.0
				_idle_s = 0.0
				_set_state(State.IDLE)
			else:
				velocity.x = signf(dx) * WALK_SPEED_PX_S


func _set_state(next: int) -> void:
	_state = next
	_state_s = 0.0


func _aim_arm(to_player: Vector2) -> void:
	var local_dir: Vector2 = Vector2(to_player.x * float(_facing), to_player.y)
	_arm.rotation = local_dir.angle()


func _build_figure() -> void:
	var legs: Polygon2D = Polygon2D.new()
	legs.polygon = DrawUtil.rect_points(17.0, 17.0)
	legs.position = Vector2(0.0, 14.5)
	legs.color = Color(0.23, 0.16, 0.14)
	_figure.add_child(legs)
	var coat: Polygon2D = Polygon2D.new()
	coat.polygon = DrawUtil.rect_points(22.0, 24.0)
	coat.position = Vector2(0.0, -3.0)
	coat.color = Color(0.62, 0.25, 0.17)
	_figure.add_child(coat)
	var head: Polygon2D = Polygon2D.new()
	head.polygon = DrawUtil.circle_points(7.0)
	head.position = Vector2(0.0, -20.0)
	head.color = Color(0.85, 0.64, 0.5)
	_figure.add_child(head)
	var brim: Polygon2D = Polygon2D.new()
	brim.polygon = DrawUtil.rect_points(19.0, 4.0)
	brim.position = Vector2(0.0, -25.0)
	brim.color = Color(0.3, 0.18, 0.12)
	_figure.add_child(brim)
	_arm = Node2D.new()
	_arm.position = Vector2(3.0, -8.0)
	_figure.add_child(_arm)
	_gun = Polygon2D.new()
	_gun.polygon = PackedVector2Array([
		Vector2(0.0, -2.0), Vector2(25.0, -1.0), Vector2(25.0, 2.0), Vector2(0.0, 3.0),
	])
	_gun.color = GUN_REST_COLOR
	_arm.add_child(_gun)
	_muzzle = Marker2D.new()
	_muzzle.position = Vector2(27.0, 0.0)
	_arm.add_child(_muzzle)
