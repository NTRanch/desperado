class_name ScrollerEnemy
extends CharacterBody2D
## Base for every scroller combatant that is not the player: hit
## points, the Truth weak-point mark, hit flash, and the death pop.
## Contract: bolts call take_bolt_hit(damage, form, from_pos); the
## hit returns true (absorbed). A Truth hit marks the enemy for
## MARK_DURATION_S; while marked, every later hit deals
## MARK_DAMAGE_MULT times damage (the marking hit itself does not).
## Subclasses size the body via setup_body(), draw into the figure
## node, and move by implementing act(); this base owns mark/flash
## timers, gravity, and move_and_slide().

signal died(enemy: ScrollerEnemy)

const MARK_DURATION_S: float = 10.0
const MARK_DAMAGE_MULT: int = 3
const GRAVITY_PX_S2: float = 1400.0
const FLASH_S: float = 0.08
const POP_TIME_S: float = 0.16
const LAYER_ENEMY: int = 4
const MASK_WORLD: int = 1

var max_hp: int = 6
var hp: int = 6
var pop_color: Color = Color(0.9, 0.5, 0.3)
## The combatant this enemy fights; set by the level at spawn.
var player: Node2D = null

var _marked_s: float = 0.0
var _flash_s: float = 0.0
var _body_w: float = 26.0
var _body_h: float = 46.0
var _figure: Node2D
var _marker: Polygon2D


func _ready() -> void:
	add_to_group("enemies")
	collision_layer = LAYER_ENEMY
	collision_mask = MASK_WORLD


## Builds the collision box, the figure root subclasses draw into,
## and the weak-point marker. Call once from the subclass _ready.
func setup_body(width: float, height: float) -> void:
	_body_w = width
	_body_h = height
	var shape_node: CollisionShape2D = CollisionShape2D.new()
	var rect: RectangleShape2D = RectangleShape2D.new()
	rect.size = Vector2(width, height)
	shape_node.shape = rect
	add_child(shape_node)
	_figure = Node2D.new()
	add_child(_figure)
	_marker = Polygon2D.new()
	_marker.polygon = DrawUtil.diamond_points(11.0, 15.0)
	_marker.color = Color(1.0, 0.84, 0.2)
	_marker.position = Vector2(0.0, -height * 0.5 - 16.0)
	_marker.visible = false
	add_child(_marker)


## Half the body height; the level seats spawns on surfaces with it.
func half_height() -> float:
	return _body_h * 0.5


## True while a Truth weak-point mark is live.
func is_marked() -> bool:
	return _marked_s > 0.0


## The one damage path (bolts call this). Returns true: the hit is
## absorbed, even when it kills.
func take_bolt_hit(damage_value: int, hit_form: int, _from_pos: Vector2) -> bool:
	if hp <= 0:
		return true
	var dealt: int = damage_value
	if is_marked():
		dealt *= MARK_DAMAGE_MULT
	if hit_form == LaForma.Form.TRUTH:
		_marked_s = MARK_DURATION_S
	hp -= dealt
	_flash_s = FLASH_S
	if hp <= 0:
		_die()
	return true


## Movement/AI hook. Subclasses set velocity here; the base applies
## gravity before the call and move_and_slide() after it.
func act(_delta: float) -> void:
	pass


func _physics_process(delta: float) -> void:
	if _marked_s > 0.0:
		_marked_s = maxf(0.0, _marked_s - delta)
	if _marker != null:
		_marker.visible = is_marked()
	if _figure != null:
		if _flash_s > 0.0:
			_flash_s -= delta
			_figure.modulate = Color(2.4, 2.4, 2.4)
		elif _figure.modulate != Color.WHITE:
			_figure.modulate = Color.WHITE
	if is_on_floor():
		velocity.y = 1.0
	else:
		velocity.y += GRAVITY_PX_S2 * delta
	act(delta)
	move_and_slide()


func _die() -> void:
	died.emit(self)
	var parent: Node = get_parent()
	if parent != null:
		var ghost: Polygon2D = Polygon2D.new()
		ghost.polygon = DrawUtil.rect_points(_body_w, _body_h)
		ghost.color = pop_color
		parent.add_child(ghost)
		ghost.global_position = global_position
		var tween: Tween = ghost.create_tween()
		tween.set_parallel(true)
		tween.tween_property(ghost, "scale", Vector2(1.8, 1.8), POP_TIME_S)
		tween.tween_property(ghost, "modulate:a", 0.0, POP_TIME_S)
		tween.chain().tween_callback(ghost.queue_free)
	queue_free()
