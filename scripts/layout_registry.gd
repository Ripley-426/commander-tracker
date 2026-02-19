extends RefCounted
class_name LayoutRegistry

const LAYOUTS: Array[Dictionary] = [
	{"id": "p2_head_to_head", "name": "Head-to-Head", "player_count": 2},
	{"id": "p3_side_left", "name": "Two Opposed + Side Left", "player_count": 3},
	{"id": "p3_side_right", "name": "Two Opposed + Side Right", "player_count": 3},
	{"id": "p4_two_facing_two", "name": "Two Facing Two", "player_count": 4},
	{"id": "p4_side_seats", "name": "Opposed + Two Side Seats", "player_count": 4},
	{"id": "p5_side_bias_left", "name": "Opposed Core + Side Bias Left", "player_count": 5},
	{"id": "p5_side_bias_right", "name": "Opposed Core + Side Bias Right", "player_count": 5},
	{"id": "p6_three_vs_three", "name": "Three Facing Three", "player_count": 6},
	{"id": "p6_two_vs_two_sides", "name": "Two Facing Two + Side Seats", "player_count": 6}
]

static func get_layout_presets(player_count: int) -> Array[Dictionary]:
	var presets: Array[Dictionary] = []
	for layout: Dictionary in LAYOUTS:
		if int(layout.get("player_count", 0)) != player_count:
			continue
		presets.append({
			"id": str(layout.get("id", "")),
			"name": str(layout.get("name", ""))
		})
	return presets

static func get_slots(layout_id: String, player_count: int) -> Array[Dictionary]:
	var raw_slots: Array[Dictionary]
	match layout_id:
		"p2_head_to_head":
			raw_slots = _p2_head_to_head()
		"p3_side_left":
			raw_slots = _p3_side_left()
		"p3_side_right":
			raw_slots = _p3_side_right()
		"p4_two_facing_two":
			raw_slots = _p4_two_facing_two()
		"p4_side_seats":
			raw_slots = _p4_side_seats()
		"p5_side_bias_left":
			raw_slots = _p5_side_bias_left()
		"p5_side_bias_right":
			raw_slots = _p5_side_bias_right()
		"p6_three_vs_three":
			raw_slots = _p6_three_vs_three()
		"p6_two_vs_two_sides":
			raw_slots = _p6_two_vs_two_sides()
		_:
			raw_slots = _fallback_grid(player_count)
	return _maximize_slots(raw_slots, 0.0)

static func _rect(x: float, y: float, w: float, h: float) -> Dictionary:
	return {"x": x, "y": y, "w": w, "h": h}

static func _p2_head_to_head() -> Array[Dictionary]:
	return [
		_rect(0.00, 0.00, 1.00, 0.50),
		_rect(0.00, 0.50, 1.00, 0.50)
	]

static func _p3_side_left() -> Array[Dictionary]:
	return [
		_rect(0.28, 0.00, 0.72, 0.50),
		_rect(0.28, 0.50, 0.72, 0.50),
		_rect(0.00, 0.00, 0.28, 1.00)
	]

static func _p3_side_right() -> Array[Dictionary]:
	return [
		_rect(0.00, 0.00, 0.72, 0.50),
		_rect(0.00, 0.50, 0.72, 0.50),
		_rect(0.72, 0.00, 0.28, 1.00)
	]

static func _p4_two_facing_two() -> Array[Dictionary]:
	return [
		_rect(0.00, 0.00, 0.50, 0.50),
		_rect(0.50, 0.00, 0.50, 0.50),
		_rect(0.00, 0.50, 0.50, 0.50),
		_rect(0.50, 0.50, 0.50, 0.50)
	]

static func _p4_side_seats() -> Array[Dictionary]:
	return [
		_rect(0.20, 0.00, 0.60, 0.50),
		_rect(0.20, 0.50, 0.60, 0.50),
		_rect(0.00, 0.25, 0.20, 0.50),
		_rect(0.80, 0.25, 0.20, 0.50)
	]

static func _p5_side_bias_left() -> Array[Dictionary]:
	return [
		_rect(0.20, 0.00, 0.60, 0.45),
		_rect(0.20, 0.55, 0.60, 0.45),
		_rect(0.00, 0.00, 0.20, 0.50),
		_rect(0.00, 0.50, 0.20, 0.50),
		_rect(0.80, 0.25, 0.20, 0.50)
	]

static func _p5_side_bias_right() -> Array[Dictionary]:
	return [
		_rect(0.20, 0.00, 0.60, 0.45),
		_rect(0.20, 0.55, 0.60, 0.45),
		_rect(0.80, 0.00, 0.20, 0.50),
		_rect(0.80, 0.50, 0.20, 0.50),
		_rect(0.00, 0.25, 0.20, 0.50)
	]

static func _p6_three_vs_three() -> Array[Dictionary]:
	return [
		_rect(0.00, 0.00, 0.333333, 0.50),
		_rect(0.333333, 0.00, 0.333333, 0.50),
		_rect(0.666666, 0.00, 0.333334, 0.50),
		_rect(0.00, 0.50, 0.333333, 0.50),
		_rect(0.333333, 0.50, 0.333333, 0.50),
		_rect(0.666666, 0.50, 0.333334, 0.50)
	]

static func _p6_two_vs_two_sides() -> Array[Dictionary]:
	return [
		_rect(0.20, 0.00, 0.30, 0.50),
		_rect(0.50, 0.00, 0.30, 0.50),
		_rect(0.20, 0.50, 0.30, 0.50),
		_rect(0.50, 0.50, 0.30, 0.50),
		_rect(0.00, 0.25, 0.20, 0.50),
		_rect(0.80, 0.25, 0.20, 0.50)
	]

static func _fallback_grid(player_count: int) -> Array[Dictionary]:
	var count: int = max(player_count, 1)
	var cols: int = 3 if count > 4 else 2
	var rows: int = int(ceil(float(count) / float(cols)))
	var margin_x: float = 0.03
	var margin_y: float = 0.05
	var gap_x: float = 0.02
	var gap_y: float = 0.03
	var width: float = (1.0 - (2.0 * margin_x) - (float(cols - 1) * gap_x)) / float(cols)
	var height: float = (1.0 - (2.0 * margin_y) - (float(rows - 1) * gap_y)) / float(rows)

	var slots: Array[Dictionary] = []
	for i: int in range(count):
		var row: int = int(i / cols)
		var col: int = i % cols
		var x: float = margin_x + float(col) * (width + gap_x)
		var y: float = margin_y + float(row) * (height + gap_y)
		slots.append(_rect(x, y, width, height))
	return slots

static func _maximize_slots(slots: Array[Dictionary], margin: float) -> Array[Dictionary]:
	if slots.is_empty():
		return slots

	var min_x: float = 1.0
	var min_y: float = 1.0
	var max_x: float = 0.0
	var max_y: float = 0.0

	for slot: Dictionary in slots:
		var x: float = float(slot.get("x", 0.0))
		var y: float = float(slot.get("y", 0.0))
		var w: float = float(slot.get("w", 0.0))
		var h: float = float(slot.get("h", 0.0))
		min_x = min(min_x, x)
		min_y = min(min_y, y)
		max_x = max(max_x, x + w)
		max_y = max(max_y, y + h)

	var source_width: float = max(max_x - min_x, 0.001)
	var source_height: float = max(max_y - min_y, 0.001)
	var target_min: float = margin
	var target_max: float = 1.0 - margin
	var target_size: float = target_max - target_min

	var normalized: Array[Dictionary] = []
	for slot: Dictionary in slots:
		var x: float = float(slot.get("x", 0.0))
		var y: float = float(slot.get("y", 0.0))
		var w: float = float(slot.get("w", 0.0))
		var h: float = float(slot.get("h", 0.0))

		var nx: float = target_min + ((x - min_x) / source_width) * target_size
		var ny: float = target_min + ((y - min_y) / source_height) * target_size
		var nw: float = (w / source_width) * target_size
		var nh: float = (h / source_height) * target_size
		normalized.append(_rect(nx, ny, nw, nh))

	return normalized
