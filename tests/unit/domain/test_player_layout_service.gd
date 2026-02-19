extends GutTest

func test_get_slots_returns_expected_count_for_known_layouts() -> void:
	var layout_script: GDScript = load("res://scripts/domain/player_layout_service.gd")
	assert_eq(layout_script.get_slots("p2_head_to_head", 2).size(), 2)
	assert_eq(layout_script.get_slots("p3_side_left", 3).size(), 3)
	assert_eq(layout_script.get_slots("p4_two_facing_two", 4).size(), 4)
	assert_eq(layout_script.get_slots("p5_side_bias_left", 5).size(), 5)
	assert_eq(layout_script.get_slots("p6_three_vs_three", 6).size(), 6)

func test_get_slots_fallback_stays_within_normalized_bounds() -> void:
	var layout_script: GDScript = load("res://scripts/domain/player_layout_service.gd")
	var slots: Array[Dictionary] = layout_script.get_slots("unknown_layout", 4)
	assert_eq(slots.size(), 4)

	for slot: Dictionary in slots:
		var x: float = float(slot.get("x", -1.0))
		var y: float = float(slot.get("y", -1.0))
		var w: float = float(slot.get("w", -1.0))
		var h: float = float(slot.get("h", -1.0))
		assert_true(x >= 0.0 and x <= 1.0)
		assert_true(y >= 0.0 and y <= 1.0)
		assert_true(w > 0.0 and w <= 1.0)
		assert_true(h > 0.0 and h <= 1.0)
		assert_true(x + w <= 1.0)
		assert_true(y + h <= 1.0)

func test_get_slots_expands_layout_to_use_available_space() -> void:
	var layout_script: GDScript = load("res://scripts/domain/player_layout_service.gd")
	var slots: Array[Dictionary] = layout_script.get_slots("p2_head_to_head", 2)

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

	assert_true(min_x <= 0.011)
	assert_true(min_y <= 0.011)
	assert_true(max_x >= 0.989)
	assert_true(max_y >= 0.989)

