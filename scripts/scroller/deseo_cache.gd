class_name DeseoCache
extends Node2D
## A hidden Deseo cache (DESIGN.md: Truth exposes what the town
## hides). Invisible until a Truth bolt passes within
## REVEAL_RADIUS_PX — near the cache or into its cover — then
## revealed for good and pays out once via the revealed signal.
## Contract: the reveal scan runs per physics frame over the
## player_bolts group, whose size is bounded by fire rates and
## bolt lifetime; only bolts whose form is Truth count.

signal revealed(cache: DeseoCache)

const REVEAL_RADIUS_PX: float = 110.0

var is_revealed: bool = false

var _visual: Node2D
var _pulse_s: float = 0.0


func _ready() -> void:
	_visual = Node2D.new()
	add_child(_visual)
	var chest: Polygon2D = Polygon2D.new()
	chest.polygon = DrawUtil.rect_points(30.0, 20.0)
	chest.position = Vector2(0.0, 2.0)
	chest.color = Color(0.5, 0.36, 0.1)
	_visual.add_child(chest)
	var lid: Polygon2D = Polygon2D.new()
	lid.polygon = DrawUtil.rect_points(32.0, 8.0)
	lid.position = Vector2(0.0, -10.0)
	lid.color = Color(0.85, 0.6, 0.16)
	_visual.add_child(lid)
	var gem: Polygon2D = Polygon2D.new()
	gem.polygon = DrawUtil.diamond_points(9.0, 13.0)
	gem.position = Vector2(0.0, -1.0)
	gem.color = Color(0.4, 0.95, 0.9)
	_visual.add_child(gem)
	_visual.visible = false


## Reveals the cache. Idempotent; the payout is the level's job.
func reveal() -> void:
	if is_revealed:
		return
	is_revealed = true
	_visual.visible = true
	revealed.emit(self)


func _physics_process(_delta: float) -> void:
	if is_revealed:
		return
	for node: Node in get_tree().get_nodes_in_group("player_bolts"):
		var bolt: ScrollerBolt = node as ScrollerBolt
		if bolt == null or bolt.form != LaForma.Form.TRUTH:
			continue
		if global_position.distance_to(bolt.global_position) <= REVEAL_RADIUS_PX:
			reveal()
			return


func _process(delta: float) -> void:
	if not is_revealed:
		return
	_pulse_s += delta
	var s: float = 1.0 + 0.05 * sin(_pulse_s * 3.0)
	_visual.scale = Vector2(s, s)
