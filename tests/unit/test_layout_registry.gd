extends GutTest

func test_presets_have_matching_slot_counts() -> void:
	var registry_script: GDScript = load("res://scripts/layout_registry.gd")
	for player_count: int in range(2, 7):
		var presets: Array[Dictionary] = registry_script.get_layout_presets(player_count)
		assert_true(presets.size() > 0)
		for preset: Dictionary in presets:
			var layout_id: String = str(preset.get("id", ""))
			var slots: Array[Dictionary] = registry_script.get_slots(layout_id, player_count)
			assert_eq(slots.size(), player_count)

func test_unknown_layout_uses_fallback_count() -> void:
	var registry_script: GDScript = load("res://scripts/layout_registry.gd")
	var slots: Array[Dictionary] = registry_script.get_slots("missing_layout", 5)
	assert_eq(slots.size(), 5)
