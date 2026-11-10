class_name ScrollerBolt
extends Area2D
## One projectile in the scroller. Ownership: the shooter creates
## the bolt, arms it with fire(), and adds it to the level; the bolt
## frees itself on hit, on range expiry, or (player bolts without
## pierce) on its first solid contact.
## Contract: enemy bolts are parryable — they join the "enemy_bolts"
## group and carry beat_counted, so one bolt can pay exactly one
## Beat. Damage flows through take_bolt_hit(damage, form, from_pos)
## on the struck body and returns true when the hit was absorbed;
## an invulnerable target returns false and the bolt flies on.
## Player bolts also shoot enemy bolts down (area contact), which
## pays the shooter a Beat through earn_beat().

const MAX_LIFE_S: float = 2.0
const RADIUS_PX: float = 5.0
const LAYER_PLAYER_BOLT: int = 8
const LAYER_ENEMY_BOLT: int = 16
const MASK_PLAYER_BOLT: int = 21  # world (1) + enemies (4) + enemy bolts (16)
const MASK_ENEMY_BOLT: int = 3  # world (1) + player (2)

var velocity: Vector2 = Vector2.ZERO
var damage: int = 1
## LaForma.Form for player bolts; -1 for enemy bolts.
var form: int = -1
var from_player: bool = true
var pierce: bool = false
## Set once the bolt has paid its Beat (dodge scan or shot down).
var beat_counted: bool = false
## The firing combatant; player bolts report shot-down Beats here.
var shooter: Node = null

var _life_s: float = 0.0
var _dot: Polygon2D


func _ready() -> void:
	var shape: CollisionShape2D = CollisionShape2D.new()
	var circle: CircleShape2D = CircleShape2D.new()
	circle.radius = RADIUS_PX
	shape.shape = circle
	add_child(shape)
	_dot = Polygon2D.new()
	_dot.polygon = DrawUtil.rect_points(15.0, 5.0)
	add_child(_dot)
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)


## Arms the bolt. direction must be non-zero. Call after add_child.
func fire(origin: Vector2, direction: Vector2, speed_px_s: float, p_damage: int, p_from_player: bool, p_form: int, p_tint: Color, p_pierce: bool, p_shooter: Node) -> void:
	global_position = origin
	velocity = direction.normalized() * speed_px_s
	damage = p_damage
	from_player = p_from_player
	form = p_form
	pierce = p_pierce
	shooter = p_shooter
	_life_s = 0.0
	rotation = direction.angle()
	collision_layer = LAYER_PLAYER_BOLT if from_player else LAYER_ENEMY_BOLT
	collision_mask = MASK_PLAYER_BOLT if from_player else MASK_ENEMY_BOLT
	add_to_group("player_bolts" if from_player else "enemy_bolts")
	if _dot != null:
		_dot.color = p_tint
		if not from_player:
			_dot.polygon = DrawUtil.circle_points(5.5, 10)


func _physics_process(delta: float) -> void:
	_life_s += delta
	if _life_s > MAX_LIFE_S:
		queue_free()
		return
	global_position += velocity * delta


func _on_body_entered(body: Node2D) -> void:
	if body.has_method("take_bolt_hit"):
		var hit_player: bool = body.is_in_group("player")
		if hit_player != from_player:
			var absorbed: bool = bool(body.call("take_bolt_hit", damage, form, global_position))
			if absorbed and not pierce:
				queue_free()
			return
	if body is StaticBody2D:
		queue_free()


func _on_area_entered(area: Area2D) -> void:
	if not from_player:
		return
	if area.is_in_group("enemy_bolts"):
		area.queue_free()
		if shooter != null and shooter.has_method("earn_beat"):
			shooter.call("earn_beat")
		if not pierce:
			queue_free()
