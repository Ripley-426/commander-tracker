extends GutTest

func test_get_slots_returns_expected_count_for_known_layouts() -> void:
	var layout_script: GDScript = load("res://scripts/domain/player_layout_service.gd")
	assert_eq(layout_script.get_slots("p2_head_to_head", 2).size(), 2)
	assert_eq(layout_script.get_slots("p3_side_left", 3).size(), 3)
	assert_eq(layout_script.get_slots("p4_two_facing_two", 4).size(), 4)
	assert_eq(layout_script.get_slots("p5_side_bias_left", 5).size(), 5)
	assert_eq(layout_script.get_slots("p6_three_vs_three", 6).size(), 6)

func test_get_slots_returns_expected_count_for_portrait_layouts() -> void:
	var layout_script: GDScript = load("res://scripts/domain/player_layout_service.gd")
	assert_eq(layout_script.get_slots("p2_head_to_head", 2, true).size(), 2)
	assert_eq(layout_script.get_slots("p3_side_left", 3, true).size(), 3)
	assert_eq(layout_script.get_slots("p4_two_facing_two", 4, true).size(), 4)
	assert_eq(layout_script.get_slots("p5_side_bias_left", 5, true).size(), 5)
	assert_eq(layout_script.get_slots("p6_three_vs_three", 6, true).size(), 6)

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

func test_get_slots_resolves_mismatched_layout_to_requested_player_count() -> void:
	var layout_script: GDScript = load("res://scripts/domain/player_layout_service.gd")
	var slots: Array[Dictionary] = layout_script.get_slots("p4_two_facing_two", 2, true)
	assert_eq(slots.size(), 2)
	for slot: Dictionary in slots:
		assert_true(slot.has("rotation_degrees"))

func test_get_slots_resolves_mismatched_layout_for_three_player_count() -> void:
	var layout_script: GDScript = load("res://scripts/domain/player_layout_service.gd")
	var slots: Array[Dictionary] = layout_script.get_slots("p4_two_facing_two", 3, true)
	assert_eq(slots.size(), 3)

func test_portrait_two_player_layout_uses_top_bottom_split() -> void:
	var layout_script: GDScript = load("res://scripts/domain/player_layout_service.gd")
	var slots: Array[Dictionary] = layout_script.get_slots("p2_head_to_head", 2, true)
	assert_eq(slots.size(), 2)
	var top_slot: Dictionary = slots[0]
	var bottom_slot: Dictionary = slots[1]
	assert_eq(float(top_slot.get("x", -1.0)), 0.0)
	assert_eq(float(top_slot.get("y", -1.0)), 0.0)
	assert_eq(float(top_slot.get("w", -1.0)), 1.0)
	assert_eq(float(top_slot.get("h", -1.0)), 0.5)
	assert_eq(float(top_slot.get("rotation_degrees", -1.0)), 180.0)
	assert_eq(float(bottom_slot.get("x", -1.0)), 0.0)
	assert_eq(float(bottom_slot.get("y", -1.0)), 0.5)
	assert_eq(float(bottom_slot.get("w", -1.0)), 1.0)
	assert_eq(float(bottom_slot.get("h", -1.0)), 0.5)
	assert_eq(float(bottom_slot.get("rotation_degrees", -1.0)), 0.0)

func test_portrait_three_player_side_left_uses_opposed_vertical_split_plus_side_band() -> void:
	var layout_script: GDScript = load("res://scripts/domain/player_layout_service.gd")
	var slots: Array[Dictionary] = layout_script.get_slots("p3_side_left", 3, true)
	assert_eq(slots.size(), 3)
	assert_true(float(slots[0].get("w", 0.0)) > 1.0)
	assert_true(float(slots[1].get("w", 0.0)) > 1.0)
	assert_eq(float(slots[2].get("y", -1.0)), 0.62)
	assert_eq(float(slots[2].get("h", -1.0)), 0.38)

func test_portrait_three_player_side_right_uses_opposed_vertical_split_plus_side_band() -> void:
	var layout_script: GDScript = load("res://scripts/domain/player_layout_service.gd")
	var slots: Array[Dictionary] = layout_script.get_slots("p3_side_right", 3, true)
	assert_eq(slots.size(), 3)
	assert_true(float(slots[0].get("w", 0.0)) > 1.0)
	assert_true(float(slots[1].get("w", 0.0)) > 1.0)
	assert_eq(float(slots[2].get("y", -1.0)), 0.0)
	assert_eq(float(slots[2].get("h", -1.0)), 0.38)

func test_portrait_five_player_layout_uses_three_plus_two_columns() -> void:
	var layout_script: GDScript = load("res://scripts/domain/player_layout_service.gd")
	var slots: Array[Dictionary] = layout_script.get_slots("p5_side_bias_left", 5, true)
	assert_eq(slots.size(), 5)
	# Three-seat column uses narrower pre-rotation widths; two-seat column uses wider widths.
	assert_eq(float(slots[0].get("w", -1.0)), 0.592592)
	assert_eq(float(slots[1].get("w", -1.0)), 0.592592)
	assert_eq(float(slots[2].get("w", -1.0)), 0.592592)
	assert_eq(float(slots[3].get("w", -1.0)), 0.888889)
	assert_eq(float(slots[4].get("w", -1.0)), 0.888889)

func test_portrait_six_player_layout_uses_two_three_stacked_columns() -> void:
	var layout_script: GDScript = load("res://scripts/domain/player_layout_service.gd")
	var slots: Array[Dictionary] = layout_script.get_slots("p6_three_vs_three", 6, true)
	assert_eq(slots.size(), 6)
	for slot: Dictionary in slots:
		assert_eq(float(slot.get("w", -1.0)), 0.592592)

