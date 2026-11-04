class_name ShiftFx
extends Node2D
## The shift snap — the game's one signature effect (DESIGN.md):
## silhouette smear + palette ring + a single drum Beat, spent on
## every morph, pass transition, and boss phase change.
##
## Photosafety contract (assets/fx/shift_snap.fx.json, lumen-fx/1
## discipline): one snap is ONE luminance pulse of 0.18 s, feathered
## in and out; the runtime refuses snaps more often than MIN_GAP_S,
## so the worst-case sustained flash rate is 1 / MIN_GAP_S = 2.0/s,
## inside the 3.0/s gate. The tools/flash_gate.py checker measures
## the record; this node only enforces the gap.

const MIN_GAP_S: float = 0.5
const PULSE_S: float = 0.18
const MAX_GHOSTS: int = 3

var _since_snap_s: float = MIN_GAP_S
var _ghosts: Array[Dictionary] = []


func _process(delta: float) -> void:
	_since_snap_s += delta
	var alive: Array[Dictionary] = []
	for ghost: Dictionary in _ghosts:
		ghost["age"] = float(ghost["age"]) + delta
		var node: Polygon2D = ghost["node"]
		if float(ghost["age"]) >= PULSE_S or not is_instance_valid(node):
			if is_instance_valid(node):
				node.queue_free()
			continue
		var t: float = float(ghost["age"]) / PULSE_S
		node.modulate.a = 0.55 * (1.0 - t)
		node.scale = Vector2(1.0 + 0.35 * t, 1.0 - 0.12 * t)
		node.position = ghost["origin"] + ghost["smear"] * t
		alive.append(ghost)
	_ghosts = alive


## Plays one snap at a position. silhouette is the caller's body
## polygon (local points + colour). Returns false when the gap
## refuses the snap (caller proceeds silently — the kata never waits
## on the effect).
func snap(origin: Vector2, silhouette: PackedVector2Array, colour: Color, facing: float) -> bool:
	if _since_snap_s < MIN_GAP_S:
		return false
	_since_snap_s = 0.0
	if _ghosts.size() >= MAX_GHOSTS:
		var oldest: Dictionary = _ghosts.pop_front()
		var old_node: Polygon2D = oldest["node"]
		if is_instance_valid(old_node):
			old_node.queue_free()
	var ghost: Polygon2D = Polygon2D.new()
	ghost.polygon = silhouette
	ghost.color = colour
	ghost.position = origin
	ghost.modulate.a = 0.55
	ghost.z_index = 40
	add_child(ghost)
	_ghosts.append({
		"node": ghost, "age": 0.0, "origin": origin,
		"smear": Vector2(cos(facing), sin(facing)) * -26.0,
	})
	return true
