class_name ScrollerBackdrop
extends Node2D
## One parallax layer of San Aurelia at dusk, drawn from code.
## kind 0 is the sky (gradient + sun), kind 1 the far silhouettes
## (mesas, rooftops, the water tower), kind 2 the mid silhouettes
## (market stalls and lamp poles). The level moves the node by
## scroll_factor each frame; drawing is deterministic (no RNG)
## and spans past the level end so offsets never uncover the sky.

const SPAN_PX: float = 5800.0
const HORIZON_PX: float = 560.0
const SKY_TOP: Color = Color(0.13, 0.07, 0.2)
const SKY_MID: Color = Color(0.55, 0.22, 0.28)
const SKY_LOW: Color = Color(0.92, 0.5, 0.22)
const FAR_COLOR: Color = Color(0.16, 0.1, 0.2)
const MESA_COLOR: Color = Color(0.24, 0.13, 0.2)
const MID_COLOR: Color = Color(0.21, 0.12, 0.15)
const LAMP_COLOR: Color = Color(0.35, 0.95, 0.85)
const WINDOW_COLOR: Color = Color(1.0, 0.75, 0.35, 0.8)

var kind: int = 0
var scroll_factor: float = 0.0


## Configures the layer; call before adding to the tree.
func setup(p_kind: int, p_factor: float) -> void:
	kind = p_kind
	scroll_factor = p_factor
	z_index = -30 + p_kind * 10
	queue_redraw()


func _draw() -> void:
	match kind:
		0:
			_draw_sky()
		1:
			_draw_far()
		2:
			_draw_mid()


func _draw_sky() -> void:
	var upper: PackedVector2Array = PackedVector2Array([
		Vector2(-400.0, -240.0), Vector2(SPAN_PX + 400.0, -240.0),
		Vector2(SPAN_PX + 400.0, 200.0), Vector2(-400.0, 200.0),
	])
	draw_polygon(upper, PackedColorArray([SKY_TOP, SKY_TOP, SKY_MID, SKY_MID]))
	var lower: PackedVector2Array = PackedVector2Array([
		Vector2(-400.0, 200.0), Vector2(SPAN_PX + 400.0, 200.0),
		Vector2(SPAN_PX + 400.0, HORIZON_PX), Vector2(-400.0, HORIZON_PX),
	])
	draw_polygon(lower, PackedColorArray([SKY_MID, SKY_MID, SKY_LOW, SKY_LOW]))
	draw_circle(Vector2(1050.0, 330.0), 120.0, Color(0.98, 0.72, 0.38, 0.3))
	draw_circle(Vector2(1050.0, 330.0), 74.0, Color(0.99, 0.8, 0.45))


func _draw_far() -> void:
	var x: float = -200.0
	var i: int = 0
	while x < SPAN_PX:
		var w: float = 150.0 + 60.0 * absf(sin(float(i) * 1.37))
		var h: float = 120.0 + 80.0 * absf(sin(float(i) * 1.93 + 0.7))
		draw_rect(Rect2(x, HORIZON_PX - h, w, h), FAR_COLOR)
		if i % 2 == 0:
			draw_rect(Rect2(x + w * 0.3, HORIZON_PX - h * 0.6, 7.0, 9.0), WINDOW_COLOR)
			draw_rect(Rect2(x + w * 0.65, HORIZON_PX - h * 0.35, 7.0, 9.0), WINDOW_COLOR)
		x += w + 26.0
		i += 1
	# Flat-top mesas behind the rooftops.
	draw_colored_polygon(PackedVector2Array([
		Vector2(2300.0, HORIZON_PX), Vector2(2360.0, HORIZON_PX - 150.0),
		Vector2(2900.0, HORIZON_PX - 150.0), Vector2(2960.0, HORIZON_PX),
	]), MESA_COLOR)
	draw_colored_polygon(PackedVector2Array([
		Vector2(3900.0, HORIZON_PX), Vector2(3950.0, HORIZON_PX - 110.0),
		Vector2(4400.0, HORIZON_PX - 110.0), Vector2(4450.0, HORIZON_PX),
	]), MESA_COLOR)
	_draw_water_tower(1500.0)


func _draw_water_tower(base_x: float) -> void:
	draw_rect(Rect2(base_x - 42.0, 300.0, 9.0, HORIZON_PX - 300.0), FAR_COLOR)
	draw_rect(Rect2(base_x + 33.0, 300.0, 9.0, HORIZON_PX - 300.0), FAR_COLOR)
	draw_rect(Rect2(base_x - 42.0, 420.0, 84.0, 7.0), FAR_COLOR)
	draw_circle(Vector2(base_x, 268.0), 47.0, FAR_COLOR)
	draw_colored_polygon(PackedVector2Array([
		Vector2(base_x - 52.0, 240.0), Vector2(base_x + 52.0, 240.0), Vector2(base_x, 196.0),
	]), FAR_COLOR)
	draw_circle(Vector2(base_x, 210.0), 4.0, LAMP_COLOR)


func _draw_mid() -> void:
	var x: float = -120.0
	var i: int = 0
	while x < SPAN_PX:
		_draw_stall(x, i)
		x += 460.0
		i += 1


func _draw_stall(x: float, i: int) -> void:
	draw_rect(Rect2(x, 430.0, 8.0, 130.0), MID_COLOR)
	draw_rect(Rect2(x + 120.0, 430.0, 8.0, 130.0), MID_COLOR)
	draw_colored_polygon(PackedVector2Array([
		Vector2(x - 14.0, 436.0), Vector2(x + 142.0, 436.0),
		Vector2(x + 128.0, 408.0), Vector2(x, 408.0),
	]), MID_COLOR)
	draw_rect(Rect2(x + 16.0, 500.0, 44.0, 60.0), MID_COLOR)
	draw_rect(Rect2(x + 66.0, 522.0, 34.0, 38.0), MID_COLOR)
	if i % 2 == 0:
		draw_circle(Vector2(x + 64.0, 452.0), 10.0, Color(LAMP_COLOR, 0.22))
		draw_circle(Vector2(x + 64.0, 452.0), 4.0, LAMP_COLOR)
