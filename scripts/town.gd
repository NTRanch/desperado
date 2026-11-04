class_name Town
extends Node2D
## San Aurelia: one town block, three Shift states.
##
## Contract: build() once; set_pass(i) re-grades palette, moves the
## pass-state props (stalls, gates, witness), and re-lights the
## workshop. Geometry is data below: buildings are boxes (drawn +
## collided), the plate texture (when generated) sits behind them as
## the vista, and palette grading is a CanvasModulate the game owns.
## The block reads the same in every pass — only its state shifts.

const WORLD_W: float = 1152.0
const GROUND_TOP: float = 300.0
const WORKSHOP_CENTRE: Vector2 = Vector2(2500, 330)

# Buildings: [x, y, w, h, colour, roof_colour]
const BUILDINGS: Array = [
	[36, 150, 170, 130, Color(0.55, 0.38, 0.26), Color(0.35, 0.20, 0.14)],
	[240, 132, 200, 148, Color(0.60, 0.42, 0.28), Color(0.38, 0.22, 0.15)],
	[700, 138, 190, 142, Color(0.52, 0.35, 0.24), Color(0.33, 0.19, 0.13)],
	[930, 158, 180, 122, Color(0.58, 0.40, 0.27), Color(0.36, 0.21, 0.14)],
]
# The workshop is BUILDINGS[1] (the family gunsmithy, centre-north).

const CACHE_POSITIONS: Dictionary = {
	"cache_well": Vector2(120, 560),
	"cache_tower": Vector2(1052, 330),
	"cache_stall": Vector2(620, 318),
	"cache_workshop": Vector2(470, 300),
	"cache_saloon": Vector2(120, 330),
	"cache_gap": Vector2(1085, 585),
}
const WITNESS_SPOTS: Array[Vector2] = [
	Vector2(560, 470), Vector2(830, 420), Vector2(300, 480),
]

var caches: Dictionary = {}  # id -> {node, found}
var witness_figure: Figure
var _plate: Sprite2D
var _sky: Polygon2D
var _gate_north: StaticBody2D
var _gate_east: StaticBody2D
var _workshop_door_pos: Vector2 = Vector2(340, 292)
var _interior_exit_pos: Vector2 = Vector2(2500, 470)
var _mother_figure: Figure


## Builds the whole block under this node.
func build(plate_texture: Texture2D) -> void:
	_sky = Polygon2D.new()
	_sky.polygon = PackedVector2Array([
		Vector2(0, 0), Vector2(WORLD_W, 0), Vector2(WORLD_W, GROUND_TOP), Vector2(0, GROUND_TOP),
	])
	_sky.z_index = -30
	add_child(_sky)
	if plate_texture != null:
		_plate = Sprite2D.new()
		_plate.texture = plate_texture
		_plate.centered = false
		_plate.position = Vector2(0, 40)
		var tex_size: Vector2 = plate_texture.get_size()
		_plate.scale = Vector2(WORLD_W / tex_size.x, 300.0 / tex_size.y)
		_plate.z_index = -20
		add_child(_plate)
	var ground: Polygon2D = Polygon2D.new()
	ground.polygon = PackedVector2Array([
		Vector2(0, GROUND_TOP), Vector2(WORLD_W, GROUND_TOP),
		Vector2(WORLD_W, 648), Vector2(0, 648),
	])
	ground.color = Color(0.62, 0.47, 0.33)
	ground.z_index = -10
	add_child(ground)
	for b: Array in BUILDINGS:
		_add_building(b)
	_add_water_tower()
	_add_well()
	_add_stalls()
	_add_lamps()
	_add_workshop_interior()
	_add_caches()
	_add_bounds()
	_gate_north = _add_gate(Vector2(576, 296), Vector2(90, 14))
	_gate_east = _add_gate(Vector2(1128, 470), Vector2(14, 90))
	witness_figure = Figure.new()
	witness_figure.build(Content.CHARACTERS["witness"])
	witness_figure.set_sidearm()
	witness_figure.position = WITNESS_SPOTS[0]
	witness_figure.z_index = 9
	add_child(witness_figure)
	set_pass(0)


## Swaps the backdrop plate (per-pass deterministic grades of one
## painting). Null keeps the current plate.
func set_plate(texture: Texture2D) -> void:
	if texture == null or _plate == null:
		return
	_plate.texture = texture
	var tex_size: Vector2 = texture.get_size()
	_plate.scale = Vector2(WORLD_W / tex_size.x, 300.0 / tex_size.y)


## Applies a pass state: palette handled by the game's modulate;
## here: gates, witness spot, stall shutters.
func set_pass(pass_index: int) -> void:
	_sky.color = Content.PASS_SKY[pass_index]
	witness_figure.position = WITNESS_SPOTS[pass_index]
	# North gate: open at dusk, closed at midnight (the town shifts),
	# open again at dawn. East gate: the reverse rhythm.
	_set_gate(_gate_north, pass_index == 1)
	_set_gate(_gate_east, pass_index == 0)
	if _mother_figure != null:
		_mother_figure.modulate.a = 0.0


## Shows/hides the workshop memory figure (flashback beats).
func set_memory_visible(visible: bool) -> void:
	if _mother_figure != null:
		_mother_figure.modulate.a = 0.85 if visible else 0.0


## The workshop door position (interact point, town side).
func workshop_door() -> Vector2:
	return _workshop_door_pos


## Where the player reappears when leaving the workshop.
func workshop_exit() -> Vector2:
	return _workshop_door_pos + Vector2(0, 26)


## The interior spawn point.
func interior_spawn() -> Vector2:
	return WORKSHOP_CENTRE + Vector2(0, 60)


## The interior exit point (interact to leave).
func interior_exit() -> Vector2:
	return _interior_exit_pos


## Marks a cache found (visual dim) and returns true once.
func collect_cache(cache_id: String) -> bool:
	if not caches.has(cache_id):
		return false
	var entry: Dictionary = caches[cache_id]
	if bool(entry["found"]):
		return false
	entry["found"] = true
	caches[cache_id] = entry
	var node: Polygon2D = entry["node"]
	node.color = Color(0.45, 0.40, 0.30, 0.5)
	return true


## Nearest unfound cache within radius, or "" (game queries Truth).
func nearest_cache(pos: Vector2, radius: float) -> String:
	var best: String = ""
	var best_dist: float = radius
	for cache_id: String in caches:
		var entry: Dictionary = caches[cache_id]
		if bool(entry["found"]):
			continue
		var node: Polygon2D = entry["node"]
		var d: float = pos.distance_to(node.global_position)
		if d < best_dist:
			best_dist = d
			best = cache_id
	return best


func _set_gate(gate: StaticBody2D, closed: bool) -> void:
	gate.visible = closed
	for child: Node in gate.get_children():
		if child is CollisionShape2D:
			(child as CollisionShape2D).disabled = not closed


func _add_gate(pos: Vector2, size: Vector2) -> StaticBody2D:
	var body: StaticBody2D = StaticBody2D.new()
	body.position = pos
	var shape: CollisionShape2D = CollisionShape2D.new()
	var rect: RectangleShape2D = RectangleShape2D.new()
	rect.size = size
	shape.shape = rect
	body.add_child(shape)
	var bars: Polygon2D = Polygon2D.new()
	bars.polygon = PackedVector2Array([
		Vector2(-size.x / 2, -size.y / 2), Vector2(size.x / 2, -size.y / 2),
		Vector2(size.x / 2, size.y / 2), Vector2(-size.x / 2, size.y / 2),
	])
	bars.color = Color(0.30, 0.22, 0.16)
	bars.z_index = 5
	body.add_child(bars)
	add_child(body)
	return body


func _add_building(b: Array) -> void:
	var x: float = b[0]
	var y: float = b[1]
	var w: float = b[2]
	var h: float = b[3]
	var wall: Polygon2D = Polygon2D.new()
	wall.polygon = PackedVector2Array([
		Vector2(x, y + 26), Vector2(x + w, y + 26), Vector2(x + w, y + h), Vector2(x, y + h),
	])
	wall.color = b[4]
	wall.z_index = 2
	add_child(wall)
	var roof: Polygon2D = Polygon2D.new()
	roof.polygon = PackedVector2Array([
		Vector2(x - 8, y + 30), Vector2(x + w + 8, y + 30),
		Vector2(x + w - 18, y), Vector2(x + 18, y),
	])
	roof.color = b[5]
	roof.z_index = 3
	add_child(roof)
	var body: StaticBody2D = StaticBody2D.new()
	body.position = Vector2(x + w / 2, y + h / 2 + 8)
	var shape: CollisionShape2D = CollisionShape2D.new()
	var rect: RectangleShape2D = RectangleShape2D.new()
	rect.size = Vector2(w, h - 16)
	shape.shape = rect
	body.add_child(shape)
	add_child(body)
	var door: Polygon2D = Polygon2D.new()
	var dx: float = x + w / 2 - 13
	door.polygon = PackedVector2Array([
		Vector2(dx, y + h - 44), Vector2(dx + 26, y + h - 44),
		Vector2(dx + 26, y + h), Vector2(dx, y + h),
	])
	door.color = Color(0.25, 0.16, 0.10)
	door.z_index = 4
	add_child(door)


func _add_water_tower() -> void:
	var base: Vector2 = Vector2(1052, 300)
	var legs: Polygon2D = Polygon2D.new()
	legs.polygon = PackedVector2Array([
		Vector2(base.x - 26, base.y + 60), Vector2(base.x - 8, base.y - 60),
		Vector2(base.x + 8, base.y - 60), Vector2(base.x + 26, base.y + 60),
	])
	legs.color = Color(0.35, 0.26, 0.18)
	legs.z_index = 2
	add_child(legs)
	var tank: Polygon2D = Polygon2D.new()
	tank.polygon = PackedVector2Array([
		Vector2(base.x - 34, base.y - 108), Vector2(base.x + 34, base.y - 108),
		Vector2(base.x + 28, base.y - 58), Vector2(base.x - 28, base.y - 58),
	])
	tank.color = Color(0.48, 0.34, 0.22)
	tank.z_index = 3
	add_child(tank)
	var body: StaticBody2D = StaticBody2D.new()
	body.position = base + Vector2(0, 20)
	var shape: CollisionShape2D = CollisionShape2D.new()
	var rect: RectangleShape2D = RectangleShape2D.new()
	rect.size = Vector2(52, 90)
	shape.shape = rect
	body.add_child(shape)
	add_child(body)


func _add_well() -> void:
	var centre: Vector2 = Vector2(120, 560)
	var ring: Polygon2D = Polygon2D.new()
	ring.polygon = PackedVector2Array([
		Vector2(centre.x - 24, centre.y - 8), Vector2(centre.x + 24, centre.y - 8),
		Vector2(centre.x + 18, centre.y + 12), Vector2(centre.x - 18, centre.y + 12),
	])
	ring.color = Color(0.45, 0.42, 0.40)
	ring.z_index = 3
	add_child(ring)
	var body: StaticBody2D = StaticBody2D.new()
	body.position = centre
	var shape: CollisionShape2D = CollisionShape2D.new()
	var rect: RectangleShape2D = RectangleShape2D.new()
	rect.size = Vector2(46, 20)
	shape.shape = rect
	body.add_child(shape)
	add_child(body)


func _add_stalls() -> void:
	var spots: Array[Vector2] = [Vector2(600, 330), Vector2(660, 330), Vector2(430, 560), Vector2(760, 580)]
	for spot: Vector2 in spots:
		var stall: Polygon2D = Polygon2D.new()
		stall.polygon = PackedVector2Array([
			Vector2(spot.x - 26, spot.y - 26), Vector2(spot.x + 26, spot.y - 26),
			Vector2(spot.x + 22, spot.y + 10), Vector2(spot.x - 22, spot.y + 10),
		])
		stall.color = Color(0.66, 0.30, 0.22)
		stall.z_index = 3
		add_child(stall)
		var body: StaticBody2D = StaticBody2D.new()
		body.position = spot
		var shape: CollisionShape2D = CollisionShape2D.new()
		var rect: RectangleShape2D = RectangleShape2D.new()
		rect.size = Vector2(50, 30)
		shape.shape = rect
		body.add_child(shape)
		add_child(body)


func _add_lamps() -> void:
	var spots: Array[Vector2] = [Vector2(200, 320), Vector2(520, 330), Vector2(880, 330), Vector2(320, 590), Vector2(940, 590)]
	for spot: Vector2 in spots:
		var post: Polygon2D = Polygon2D.new()
		post.polygon = PackedVector2Array([
			Vector2(spot.x - 2, spot.y - 44), Vector2(spot.x + 2, spot.y - 44),
			Vector2(spot.x + 2, spot.y), Vector2(spot.x - 2, spot.y),
		])
		post.color = Color(0.15, 0.13, 0.12)
		post.z_index = 4
		add_child(post)
		var glow: Polygon2D = Polygon2D.new()
		var glow_points: PackedVector2Array = PackedVector2Array()
		var segments: int = 12
		for i: int in segments:
			var angle: float = TAU * float(i) / float(segments)
			glow_points.append(spot + Vector2(0, -46) + Vector2(cos(angle), sin(angle)) * 17.0)
		glow.polygon = glow_points
		glow.color = Color(1.0, 0.72, 0.38, 0.35)
		glow.z_index = 5
		add_child(glow)


func _add_workshop_interior() -> void:
	var floor_poly: Polygon2D = Polygon2D.new()
	var c: Vector2 = WORKSHOP_CENTRE
	floor_poly.polygon = PackedVector2Array([
		Vector2(c.x - 220, c.y - 130), Vector2(c.x + 220, c.y - 130),
		Vector2(c.x + 220, c.y + 150), Vector2(c.x - 220, c.y + 150),
	])
	floor_poly.color = Color(0.36, 0.27, 0.19)
	floor_poly.z_index = -5
	add_child(floor_poly)
	_add_wall_box(c + Vector2(0, -138), Vector2(448, 16))
	_add_wall_box(c + Vector2(0, 158), Vector2(448, 16))
	_add_wall_box(c + Vector2(-228, 10), Vector2(16, 296))
	_add_wall_box(c + Vector2(228, 10), Vector2(16, 296))
	var bench: Polygon2D = Polygon2D.new()
	bench.polygon = PackedVector2Array([
		Vector2(c.x - 70, c.y - 40), Vector2(c.x + 70, c.y - 40),
		Vector2(c.x + 70, c.y - 14), Vector2(c.x - 70, c.y - 14),
	])
	bench.color = Color(0.30, 0.20, 0.12)
	bench.z_index = 3
	add_child(bench)
	_mother_figure = Figure.new()
	_mother_figure.build(Content.CHARACTERS["mother"])
	_mother_figure.position = c + Vector2(0, -70)
	_mother_figure.modulate.a = 0.0
	_mother_figure.z_index = 9
	add_child(_mother_figure)


func _add_wall_box(pos: Vector2, size: Vector2) -> void:
	var body: StaticBody2D = StaticBody2D.new()
	body.position = pos
	var shape: CollisionShape2D = CollisionShape2D.new()
	var rect: RectangleShape2D = RectangleShape2D.new()
	rect.size = size
	shape.shape = rect
	body.add_child(shape)
	add_child(body)


func _add_caches() -> void:
	for cache_id: String in CACHE_POSITIONS:
		var marker: Polygon2D = Polygon2D.new()
		var p: Vector2 = CACHE_POSITIONS[cache_id]
		marker.polygon = PackedVector2Array([
			Vector2(-8, -8), Vector2(8, -8), Vector2(8, 8), Vector2(-8, 8),
		])
		marker.position = p
		marker.color = Color(0.95, 0.80, 0.35, 0.9)
		marker.z_index = 6
		add_child(marker)
		caches[cache_id] = {"node": marker, "found": false}


func _add_bounds() -> void:
	_add_wall_box(Vector2(576, 292), Vector2(1152, 12))
	_add_wall_box(Vector2(576, 656), Vector2(1152, 12))
	_add_wall_box(Vector2(-6, 474), Vector2(12, 376))
	_add_wall_box(Vector2(1158, 474), Vector2(12, 376))
	# The broken footbridge fence (south-east yard): a fence line at
	# x=1022 with one broken band (the game enforces the crossing
	# rule there — only a Freedom dash passes; see game.GAP_ZONE).
	_add_wall_box(Vector2(1022, 515), Vector2(48, 82))
	_add_wall_box(Vector2(1022, 636), Vector2(48, 24))
	var planks: Polygon2D = Polygon2D.new()
	planks.polygon = PackedVector2Array([
		Vector2(998, 580), Vector2(1046, 580), Vector2(1046, 592), Vector2(998, 592),
	])
	planks.color = Color(0.40, 0.29, 0.18)
	planks.z_index = 1
	add_child(planks)
	var crack: Polygon2D = Polygon2D.new()
	crack.polygon = PackedVector2Array([
		Vector2(998, 556), Vector2(1046, 556), Vector2(1046, 624), Vector2(998, 624),
	])
	crack.color = Color(0.16, 0.11, 0.08)
	crack.z_index = 0
	add_child(crack)
