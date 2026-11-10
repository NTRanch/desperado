class_name ScrollerLevel
extends Node2D
## San Aurelia, Dusk pass, as a side-scroller: one block, four
## screens wide, ground line plus an awning/rooftop upper line,
## a hidden Deseo cache, and the framing-agent duel behind gates
## at the street's end. Everything is built from code; all art is
## placeholder shapes (DESIGN-ADDENDUM-20261109.md).
## Contract: the level owns the player, the enemies, the duel
## state, the camera, and the shift-snap juice wiring. Gameplay
## numbers live in the combatants' own scripts; this file owns
## only layout and presentation constants.

const LEVEL_WIDTH_PX: float = 4800.0
const GROUND_TOP_PX: float = 560.0
const GROUND_H_PX: float = 88.0
const VIEW_W_PX: float = 1152.0
const VIEW_H_PX: float = 648.0
const CAMERA_Y_PX: float = 324.0
const CAMERA_LOOKAHEAD_PX: float = 90.0
const CAMERA_DAMP: float = 10.0
const SHAKE_MAX_PX: float = 6.0
const SHAKE_DECAY_PER_S: float = 6.0
const ARENA_LEFT_PX: float = 4060.0
const ARENA_RIGHT_PX: float = 4740.0
const DUEL_TRIGGER_PX: float = 4120.0
const BOSS_X_PX: float = 4450.0
const GATE_W_PX: float = 16.0
const GATE_TOP_PX: float = 370.0
const CACHE_BEATS: int = 3
const SNAP_HITSTOP_SCALE: float = 0.05
const SNAP_HITSTOP_S: float = 0.06
const BEAT_HITSTOP_SCALE: float = 0.05
const BEAT_HITSTOP_S: float = 0.03
const SPAWN_POS: Vector2 = Vector2(120.0, 536.0)
const PLATFORMS: Array = [
	[700.0, 450.0, 450.0], [1500.0, 450.0, 400.0], [1650.0, 340.0, 500.0],
	[2400.0, 450.0, 350.0], [3100.0, 450.0, 400.0], [3350.0, 340.0, 450.0],
]
const GROUND_COLOR: Color = Color(0.32, 0.2, 0.16)
const GROUND_EDGE_COLOR: Color = Color(0.85, 0.55, 0.3)
const PLATFORM_COLOR: Color = Color(0.36, 0.22, 0.18)
const PLATFORM_EDGE_COLOR: Color = Color(0.7, 0.45, 0.26)
const CRATE_COLOR: Color = Color(0.45, 0.3, 0.18)
const GATE_COLOR: Color = Color(0.2, 0.18, 0.24)

var player: ScrollerPlayer
var boss: FramingAgent = null
var hud: ScrollerHud
var enemies: Array[ScrollerEnemy] = []
var duel_started: bool = false
var cleared: bool = false
var gates_locked: bool = false
var elapsed_s: float = 0.0
var caches_found: int = 0

var _silhouette: PackedVector2Array = PackedVector2Array([
	Vector2(-10.0, -30.0), Vector2(8.0, -30.0), Vector2(11.0, -12.0),
	Vector2(9.0, 10.0), Vector2(11.0, 24.0), Vector2(3.0, 24.0),
	Vector2(1.0, 10.0), Vector2(-3.0, 10.0), Vector2(-5.0, 24.0),
	Vector2(-11.0, 24.0), Vector2(-9.0, 8.0),
])
var _camera: Camera2D
var _fx: ShiftFx
var _backdrops: Array[ScrollerBackdrop] = []
var _gate_shapes: Array[CollisionShape2D] = []
var _gate_visuals: Array[Polygon2D] = []
var _shake: float = 0.0
var _hitstop_gen: int = 0
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()


func _ready() -> void:
	_rng.seed = 20261109
	_build_backdrop()
	_build_world()
	_build_gates()
	_build_cache()
	_spawn_player()
	_spawn_street()
	_build_duel_trigger()
	_build_camera()
	hud = ScrollerHud.new()
	add_child(hud)
	_fx = ShiftFx.new()
	add_child(_fx)
	player.beat_earned.connect(_on_beat_earned)
	player.shifted.connect(_on_shifted)
	player.died.connect(_on_player_died)


## Locks the arena gates and spawns the framing agent. Called by
## the street trigger; idempotent, and the smoke gate calls it too.
func start_duel() -> void:
	if duel_started:
		return
	duel_started = true
	_set_gates(true)
	boss = FramingAgent.new()
	boss.position = Vector2(BOSS_X_PX, GROUND_TOP_PX - FramingAgent.BODY_H * 0.5)
	boss.arena_min_x = ARENA_LEFT_PX + 40.0
	boss.arena_max_x = ARENA_RIGHT_PX - 40.0
	boss.player = player
	add_child(boss)
	boss.died.connect(_on_boss_died)
	hud.show_boss(boss)
	hud.toast("THE FRAMING AGENT")


## Plays a hit-stop: time_scale dips for real_s of real time.
## Overlapping stops are generation-tokened; only the latest
## restores the scale.
func hit_stop(scale: float, real_s: float) -> void:
	_hitstop_gen += 1
	var gen: int = _hitstop_gen
	Engine.time_scale = scale
	await get_tree().create_timer(real_s, true, false, true).timeout
	if gen == _hitstop_gen and is_inside_tree():
		Engine.time_scale = 1.0


func _process(delta: float) -> void:
	var udelta: float = delta / Engine.time_scale if Engine.time_scale > 0.0 else delta
	if not cleared:
		elapsed_s += udelta
	_update_camera(delta, udelta)
	hud.refresh(player, elapsed_s)


func _physics_process(_delta: float) -> void:
	player.global_position.x = clampf(player.global_position.x, 30.0, LEVEL_WIDTH_PX - 30.0)


func _update_camera(delta: float, udelta: float) -> void:
	var target_x: float = player.global_position.x + float(player.facing) * CAMERA_LOOKAHEAD_PX
	target_x = clampf(target_x, VIEW_W_PX * 0.5, LEVEL_WIDTH_PX - VIEW_W_PX * 0.5)
	var t: float = minf(1.0, CAMERA_DAMP * delta)
	_camera.position = Vector2(lerpf(_camera.position.x, target_x, t), CAMERA_Y_PX)
	if _shake > 0.0:
		_shake = maxf(0.0, _shake - SHAKE_DECAY_PER_S * udelta)
		_camera.offset = Vector2(
			_rng.randf_range(-1.0, 1.0), _rng.randf_range(-1.0, 1.0)) * SHAKE_MAX_PX * _shake
	elif _camera.offset != Vector2.ZERO:
		_camera.offset = Vector2.ZERO
	for layer: ScrollerBackdrop in _backdrops:
		layer.position.x = _camera.position.x * layer.scroll_factor


func _on_beat_earned() -> void:
	hit_stop(BEAT_HITSTOP_SCALE, BEAT_HITSTOP_S)
	hud.pulse_pips()


func _on_shifted(form: int) -> void:
	var color: Color = LaForma.color_of(form)
	_fx.snap(player.global_position, _silhouette, color, 0.0 if player.facing > 0 else PI)
	hud.flash(color)
	_shake = 1.0
	hit_stop(SNAP_HITSTOP_SCALE, SNAP_HITSTOP_S)


func _on_player_died() -> void:
	player.respawn(SPAWN_POS)
	hud.toast("DOWN — THE STREET GIVES YOU BACK")


func _on_boss_died(_enemy: ScrollerEnemy) -> void:
	cleared = true
	_set_gates(false)
	hud.hide_boss()
	hud.show_clear(elapsed_s)


func _on_cache_revealed(_cache: DeseoCache) -> void:
	caches_found += 1
	player.add_beats(CACHE_BEATS)
	hud.toast("DESEO CACHE FOUND — BEATS +%d" % CACHE_BEATS)


func _on_duel_trigger(body: Node2D) -> void:
	if body == player:
		start_duel()


func _set_gates(locked: bool) -> void:
	gates_locked = locked
	for shape: CollisionShape2D in _gate_shapes:
		shape.disabled = not locked
	for visual: Polygon2D in _gate_visuals:
		visual.modulate.a = 1.0 if locked else 0.3


func _build_backdrop() -> void:
	var kinds: Array = [[0, 1.0], [1, 0.3], [2, 0.55]]
	for entry: Array in kinds:
		var layer: ScrollerBackdrop = ScrollerBackdrop.new()
		layer.setup(int(entry[0]), float(entry[1]))
		add_child(layer)
		_backdrops.append(layer)


func _build_world() -> void:
	_static_box(0.0, GROUND_TOP_PX, LEVEL_WIDTH_PX, GROUND_H_PX, GROUND_COLOR, GROUND_EDGE_COLOR)
	for spec: Array in PLATFORMS:
		_static_box(float(spec[0]), float(spec[1]), float(spec[2]), 18.0, PLATFORM_COLOR, PLATFORM_EDGE_COLOR)
	_static_box(1450.0, GROUND_TOP_PX - 44.0, 44.0, 44.0, CRATE_COLOR, PLATFORM_EDGE_COLOR)
	_static_box(2560.0, GROUND_TOP_PX - 44.0, 44.0, 44.0, CRATE_COLOR, PLATFORM_EDGE_COLOR)
	_static_box(3980.0, GROUND_TOP_PX - 44.0, 44.0, 44.0, CRATE_COLOR, PLATFORM_EDGE_COLOR)
	# The cache's cover crate, up on the second rooftop.
	_static_box(3540.0, 340.0 - 44.0, 44.0, 44.0, CRATE_COLOR, PLATFORM_EDGE_COLOR)


## One static box: a StaticBody2D with a filled polygon and a lit
## top edge. (x, y_top) is the box's top-left corner.
func _static_box(x: float, y_top: float, w: float, h: float, color: Color, edge: Color) -> StaticBody2D:
	var body: StaticBody2D = StaticBody2D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	body.position = Vector2(x + w * 0.5, y_top + h * 0.5)
	var shape: CollisionShape2D = CollisionShape2D.new()
	var rect: RectangleShape2D = RectangleShape2D.new()
	rect.size = Vector2(w, h)
	shape.shape = rect
	body.add_child(shape)
	var fill: Polygon2D = Polygon2D.new()
	fill.polygon = DrawUtil.rect_points(w, h)
	fill.color = color
	body.add_child(fill)
	var lip: Polygon2D = Polygon2D.new()
	lip.polygon = DrawUtil.rect_points(w, 5.0)
	lip.position = Vector2(0.0, -h * 0.5 + 2.5)
	lip.color = edge
	body.add_child(lip)
	add_child(body)
	return body


func _build_gates() -> void:
	for gate_x: float in [ARENA_LEFT_PX, ARENA_RIGHT_PX]:
		var body: StaticBody2D = StaticBody2D.new()
		body.collision_layer = 1
		body.collision_mask = 0
		body.position = Vector2(gate_x, (GATE_TOP_PX + GROUND_TOP_PX) * 0.5)
		var shape: CollisionShape2D = CollisionShape2D.new()
		var rect: RectangleShape2D = RectangleShape2D.new()
		rect.size = Vector2(GATE_W_PX, GROUND_TOP_PX - GATE_TOP_PX)
		shape.shape = rect
		shape.disabled = true
		body.add_child(shape)
		var visual: Polygon2D = Polygon2D.new()
		visual.polygon = DrawUtil.rect_points(GATE_W_PX, GROUND_TOP_PX - GATE_TOP_PX)
		visual.color = GATE_COLOR
		visual.modulate.a = 0.3
		body.add_child(visual)
		var stripe: Polygon2D = Polygon2D.new()
		stripe.polygon = DrawUtil.rect_points(GATE_W_PX, 8.0)
		stripe.position = Vector2(0.0, -40.0)
		stripe.color = Color(0.95, 0.65, 0.2)
		body.add_child(stripe)
		add_child(body)
		_gate_shapes.append(shape)
		_gate_visuals.append(visual)


func _build_cache() -> void:
	var cache: DeseoCache = DeseoCache.new()
	cache.position = Vector2(3620.0, 324.0)
	add_child(cache)
	cache.revealed.connect(_on_cache_revealed)


func _spawn_player() -> void:
	player = ScrollerPlayer.new()
	player.position = SPAWN_POS
	add_child(player)


func _spawn_street() -> void:
	_spawn_rifleman(1050.0, GROUND_TOP_PX)
	_spawn_rusher(1450.0, GROUND_TOP_PX)
	_spawn_rifleman(1750.0, 450.0)
	_spawn_rusher(2300.0, GROUND_TOP_PX)
	_spawn_rifleman(2900.0, GROUND_TOP_PX)
	_spawn_rusher(3400.0, GROUND_TOP_PX)


func _spawn_rifleman(x: float, surface_top: float) -> void:
	var enemy: ScrollerRifleman = ScrollerRifleman.new()
	enemy.position = Vector2(x, surface_top - ScrollerRifleman.BODY_H * 0.5 - 1.0)
	enemy.player = player
	add_child(enemy)
	enemies.append(enemy)


func _spawn_rusher(x: float, surface_top: float) -> void:
	var enemy: ScrollerRusher = ScrollerRusher.new()
	enemy.position = Vector2(x, surface_top - ScrollerRusher.BODY_H * 0.5 - 1.0)
	enemy.player = player
	add_child(enemy)
	enemies.append(enemy)


func _build_duel_trigger() -> void:
	var trigger: Area2D = Area2D.new()
	trigger.collision_layer = 0
	trigger.collision_mask = 2
	trigger.position = Vector2(DUEL_TRIGGER_PX, 460.0)
	var shape: CollisionShape2D = CollisionShape2D.new()
	var rect: RectangleShape2D = RectangleShape2D.new()
	rect.size = Vector2(30.0, 200.0)
	shape.shape = rect
	trigger.add_child(shape)
	add_child(trigger)
	trigger.body_entered.connect(_on_duel_trigger)


func _build_camera() -> void:
	_camera = Camera2D.new()
	_camera.position = Vector2(VIEW_W_PX * 0.5, CAMERA_Y_PX)
	add_child(_camera)
	_camera.make_current()
