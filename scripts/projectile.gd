class_name Projectile
extends Area2D
## A pooled projectile. Ownership: the firing combatant arms it via
## fire(); it frees itself on hit, on range expiry, or on wall contact.
##
## Contract: speed and lifetime are bounded by constants; damage is
## delivered through the target's take_hit(damage, from_pos) method.

const MAX_LIFE_S: float = 1.6
const RADIUS_PX: float = 5.0

var velocity: Vector2 = Vector2.ZERO
var damage: int = 0
var from_player: bool = true
var life_s: float = 0.0
var pierce: bool = false
var tint: Color = Color.WHITE
## The shooter's La Forma form (player shots); -1 for enemy shots.
var form: int = -1

var _dot: Polygon2D


func _ready() -> void:
	var shape: CollisionShape2D = CollisionShape2D.new()
	var circle: CircleShape2D = CircleShape2D.new()
	circle.radius = RADIUS_PX
	shape.shape = circle
	add_child(shape)
	_dot = Polygon2D.new()
	_dot.polygon = PackedVector2Array([
		Vector2(-7, -2.5), Vector2(7, -2.5), Vector2(7, 2.5), Vector2(-7, 2.5),
	])
	add_child(_dot)
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)


## Arms the projectile. direction must be non-zero.
func fire(origin: Vector2, direction: Vector2, speed_px_s: float, p_damage: int, p_from_player: bool, p_tint: Color, p_pierce: bool = false) -> void:
	global_position = origin
	velocity = direction.normalized() * speed_px_s
	damage = p_damage
	from_player = p_from_player
	pierce = p_pierce
	tint = p_tint
	life_s = 0.0
	rotation = direction.angle()
	if _dot != null:
		_dot.color = p_tint


func _physics_process(delta: float) -> void:
	life_s += delta
	if life_s > MAX_LIFE_S:
		queue_free()
		return
	global_position += velocity * delta


func _on_body_entered(body: Node2D) -> void:
	if body.has_method("projectile_hit"):
		var hit_player: bool = body.get("is_player") == true
		if hit_player != from_player:
			body.projectile_hit(damage, global_position, form)
			if not pierce:
				queue_free()
			return
	if body is StaticBody2D:
		queue_free()


func _on_area_entered(_area: Area2D) -> void:
	pass
