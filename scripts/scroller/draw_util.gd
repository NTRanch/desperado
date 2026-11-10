class_name DrawUtil
extends RefCounted
## Shared polygon builders for the scroller's code-drawn figures.
## Contract: points are centred on the origin; callers own placement
## and colour. Deterministic — no RNG anywhere in the slice's art.


## Axis-aligned rectangle points, width x height, centred.
static func rect_points(width: float, height: float) -> PackedVector2Array:
	var hw: float = width * 0.5
	var hh: float = height * 0.5
	return PackedVector2Array([
		Vector2(-hw, -hh), Vector2(hw, -hh), Vector2(hw, hh), Vector2(-hw, hh),
	])


## Regular polygon approximating a circle of the given radius.
static func circle_points(radius: float, segments: int = 14) -> PackedVector2Array:
	var points: PackedVector2Array = PackedVector2Array()
	points.resize(segments)
	for i: int in segments:
		var angle: float = TAU * float(i) / float(segments)
		points[i] = Vector2(cos(angle), sin(angle)) * radius
	return points


## Diamond (rhombus) points, width x height, centred.
static func diamond_points(width: float, height: float) -> PackedVector2Array:
	var hw: float = width * 0.5
	var hh: float = height * 0.5
	return PackedVector2Array([
		Vector2(0.0, -hh), Vector2(hw, 0.0), Vector2(0.0, hh), Vector2(-hw, 0.0),
	])
