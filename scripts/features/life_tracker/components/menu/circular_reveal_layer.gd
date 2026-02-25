extends Control

var reveal_progress: float = 0.0
var reveal_center: Vector2 = Vector2.ZERO
var reveal_color: Color = Color(0.02, 0.02, 0.02, 1.0)
var hole_radius: float = 0.0

func set_reveal(progress: float, center: Vector2, p_hole_radius: float = 0.0) -> void:
	reveal_progress = clampf(progress, 0.0, 1.0)
	reveal_center = center
	hole_radius = max(p_hole_radius, 0.0)
	queue_redraw()

func _draw() -> void:
	if reveal_progress <= 0.0:
		return
	var max_radius: float = _get_cover_radius(reveal_center)
	var radius: float = max_radius * reveal_progress
	_draw_ring(reveal_center, radius, hole_radius, reveal_color)

func _get_cover_radius(center: Vector2) -> float:
	var corners: Array[Vector2] = [
		Vector2(0.0, 0.0),
		Vector2(size.x, 0.0),
		Vector2(0.0, size.y),
		Vector2(size.x, size.y)
	]
	var max_distance: float = 0.0
	for corner: Vector2 in corners:
		max_distance = max(max_distance, center.distance_to(corner))
	return max_distance

func _draw_ring(center: Vector2, outer_radius: float, inner_radius: float, color: Color) -> void:
	if outer_radius <= inner_radius:
		return
	var segment_count: int = 80
	for i: int in range(segment_count):
		var angle_a: float = TAU * (float(i) / float(segment_count))
		var angle_b: float = TAU * (float(i + 1) / float(segment_count))
		var outer_a: Vector2 = center + Vector2(cos(angle_a), sin(angle_a)) * outer_radius
		var outer_b: Vector2 = center + Vector2(cos(angle_b), sin(angle_b)) * outer_radius
		var inner_a: Vector2 = center + Vector2(cos(angle_a), sin(angle_a)) * inner_radius
		var inner_b: Vector2 = center + Vector2(cos(angle_b), sin(angle_b)) * inner_radius
		draw_colored_polygon(PackedVector2Array([inner_a, outer_a, outer_b]), color)
		draw_colored_polygon(PackedVector2Array([inner_a, outer_b, inner_b]), color)
