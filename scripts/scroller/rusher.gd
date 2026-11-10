class_name ScrollerRusher
extends ScrollerEnemy
## Combine rusher: advances on the player and answers proximity
## with a telegraphed melee swipe.
## Contract: the swipe lands only if the player is still in range
## when the telegraph ends, and it flows through the player's
## take_damage(), so i-frames (dodge, Freedom burst) always beat it.

const WALK_SPEED_PX_S: float = 175.0
const MELEE_RANGE_PX: float = 54.0
const SWIPE_REACH_PX: float = 66.0
const HEIGHT_BAND_PX: float = 56.0
const TELEGRAPH_S: float = 0.35
const COOLDOWN_S: float = 0.9
const SWIPE_DAMAGE: int = 2
const BODY_W: float = 30.0
const BODY_H: float = 46.0
const RUSHER_HP: int = 8
const COAT_COLOR: Color = Color(0.85, 0.45, 0.15)
const COAT_HOT_COLOR: Color = Color(1.0, 0.62, 0.2)

enum State { ADVANCE, TELEGRAPH, COOLDOWN }

var _state: int = State.ADVANCE
var _state_s: float = 0.0
var _facing: int = 1
var _coat: Polygon2D
var _arm: Polygon2D


func _ready() -> void:
	super._ready()
	max_hp = RUSHER_HP
	hp = RUSHER_HP
	pop_color = Color(0.95, 0.55, 0.2)
	setup_body(BODY_W, BODY_H)
	_build_figure()


func act(delta: float) -> void:
	_state_s += delta
	if not is_instance_valid(player):
		velocity.x = 0.0
		return
	var to_player: Vector2 = player.global_position - global_position
	if absf(to_player.x) > 2.0:
		_facing = 1 if to_player.x > 0.0 else -1
	_figure.scale.x = float(_facing)
	match _state:
		State.ADVANCE:
			if absf(to_player.x) <= MELEE_RANGE_PX and absf(to_player.y) <= HEIGHT_BAND_PX:
				velocity.x = 0.0
				_set_state(State.TELEGRAPH)
			elif absf(to_player.x) > 6.0:
				velocity.x = float(_facing) * WALK_SPEED_PX_S
			else:
				velocity.x = 0.0
		State.TELEGRAPH:
			velocity.x = 0.0
			var t: float = clampf(_state_s / TELEGRAPH_S, 0.0, 1.0)
			_coat.color = COAT_COLOR.lerp(COAT_HOT_COLOR, t)
			_arm.rotation = lerpf(0.5, -0.9, t)
			if _state_s >= TELEGRAPH_S:
				_swipe()
				_coat.color = COAT_COLOR
				_arm.rotation = 0.5
				_set_state(State.COOLDOWN)
		State.COOLDOWN:
			velocity.x = 0.0
			if _state_s >= COOLDOWN_S:
				_set_state(State.ADVANCE)


func _set_state(next: int) -> void:
	_state = next
	_state_s = 0.0


func _swipe() -> void:
	if not is_instance_valid(player):
		return
	var to_player: Vector2 = player.global_position - global_position
	if absf(to_player.x) <= SWIPE_REACH_PX and absf(to_player.y) <= HEIGHT_BAND_PX:
		if player.has_method("take_damage"):
			player.call("take_damage", SWIPE_DAMAGE, global_position)


func _build_figure() -> void:
	var legs: Polygon2D = Polygon2D.new()
	legs.polygon = DrawUtil.rect_points(20.0, 17.0)
	legs.position = Vector2(0.0, 14.5)
	legs.color = Color(0.2, 0.15, 0.13)
	_figure.add_child(legs)
	_coat = Polygon2D.new()
	_coat.polygon = DrawUtil.rect_points(28.0, 25.0)
	_coat.position = Vector2(0.0, -3.0)
	_coat.color = COAT_COLOR
	_figure.add_child(_coat)
	var head: Polygon2D = Polygon2D.new()
	head.polygon = DrawUtil.circle_points(7.5)
	head.position = Vector2(0.0, -20.0)
	head.color = Color(0.85, 0.64, 0.5)
	_figure.add_child(head)
	_arm = Polygon2D.new()
	_arm.polygon = PackedVector2Array([
		Vector2(0.0, -3.0), Vector2(26.0, -1.0), Vector2(26.0, 3.0), Vector2(0.0, 4.0),
	])
	_arm.position = Vector2(6.0, -6.0)
	_arm.rotation = 0.5
	_arm.color = Color(0.3, 0.2, 0.16)
	_figure.add_child(_arm)
