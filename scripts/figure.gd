class_name Figure
extends Node2D
## A code-drawn character figure: coat, head, hat, and a gun whose
## silhouette changes with La Forma. Palette comes from the character
## record (content.gd); no raster art is required to read who this is
## at field size — the silhouette key is coat + hat + gun shape.
##
## Contract: build() once; set_form() re-shapes the gun; set_facing()
## flips; walk_bob() is called by the owner with distance travelled.

const BODY_POINTS: PackedVector2Array = [
	Vector2(-11, -34), Vector2(11, -34), Vector2(14, 10),
	Vector2(7, 26), Vector2(-7, 26), Vector2(-14, 10),
]
const HEAD_CENTRE: Vector2 = Vector2(0, -44)

var _gun: Polygon2D
var _body: Polygon2D
var _bob_phase: float = 0.0
var _form: int = 0


## Builds the figure under this node from a character record entry.
## Idempotent: prior build children are freed first (duel retries
## re-arm duelists, which rebuilds their figures).
func build(character: Dictionary) -> void:
	for child: Node in get_children():
		child.queue_free()
	_gun = null
	_body = null
	var shadow: Polygon2D = Polygon2D.new()
	shadow.polygon = PackedVector2Array([
		Vector2(-13, 24), Vector2(13, 24), Vector2(9, 30), Vector2(-9, 30),
	])
	shadow.color = Color(0, 0, 0, 0.30)
	add_child(shadow)
	_body = Polygon2D.new()
	_body.polygon = BODY_POINTS
	_body.color = character["coat"]
	add_child(_body)
	var head: Polygon2D = Polygon2D.new()
	head.polygon = _circle_points(HEAD_CENTRE, 9.0)
	head.color = character["skin"]
	add_child(head)
	var hair: Polygon2D = Polygon2D.new()
	hair.polygon = PackedVector2Array([
		Vector2(-10, -46), Vector2(10, -46), Vector2(10, -51), Vector2(-10, -51),
	])
	hair.color = character["hair"]
	add_child(hair)
	var hat: Polygon2D = Polygon2D.new()
	hat.polygon = PackedVector2Array([
		Vector2(-15, -50), Vector2(15, -50), Vector2(6, -58), Vector2(-6, -58),
	])
	hat.color = character["accent"]
	add_child(hat)
	_gun = Polygon2D.new()
	_gun.color = Color(0.12, 0.12, 0.14)
	add_child(_gun)
	set_form(_form)


## Re-shapes the gun to the given form (content.gd form indices).
func set_form(form: int) -> void:
	_form = form
	if _gun == null:
		return
	match form:
		Content.FORM_VENGEANCE:
			_gun.polygon = PackedVector2Array([
				Vector2(10, -18), Vector2(30, -20), Vector2(34, -12),
				Vector2(30, -6), Vector2(24, -12), Vector2(12, -10),
			])
			_gun.color = Content.FORM_COLORS[Content.FORM_VENGEANCE].darkened(0.25)
		Content.FORM_TRUTH:
			_gun.polygon = PackedVector2Array([
				Vector2(10, -20), Vector2(46, -22), Vector2(46, -18),
				Vector2(14, -14), Vector2(10, -14),
			])
			_gun.color = Content.FORM_COLORS[Content.FORM_TRUTH].darkened(0.25)
		Content.FORM_FREEDOM:
			_gun.polygon = PackedVector2Array([
				Vector2(10, -16), Vector2(28, -22), Vector2(30, -16),
				Vector2(28, -10), Vector2(12, -8),
			])
			_gun.color = Content.FORM_COLORS[Content.FORM_FREEDOM].darkened(0.25)
		_:
			_gun.polygon = PackedVector2Array([
				Vector2(10, -18), Vector2(26, -19), Vector2(26, -13), Vector2(10, -12),
			])


## A plain sidearm (duelists who do not wield the Desperado).
func set_sidearm() -> void:
	if _gun == null:
		return
	_gun.polygon = PackedVector2Array([
		Vector2(10, -18), Vector2(27, -19), Vector2(27, -13), Vector2(10, -12),
	])
	_gun.color = Color(0.15, 0.15, 0.17)


## Flips the figure toward a horizontal facing sign (-1 or +1).
func set_facing(sign_x: float) -> void:
	if sign_x != 0.0:
		scale.x = signf(sign_x)


## Advances the walk bob; call with pixels travelled this frame.
func walk_bob(distance_px: float) -> void:
	_bob_phase += distance_px * 0.09
	position.y = sin(_bob_phase) * 1.6


## The body silhouette, for shift-snap ghosts.
func silhouette() -> PackedVector2Array:
	return BODY_POINTS


func _circle_points(centre: Vector2, radius: float) -> PackedVector2Array:
	var points: PackedVector2Array = PackedVector2Array()
	var segments: int = 10
	for i: int in segments:
		var angle: float = TAU * float(i) / float(segments)
		points.append(centre + Vector2(cos(angle), sin(angle)) * radius)
	return points
