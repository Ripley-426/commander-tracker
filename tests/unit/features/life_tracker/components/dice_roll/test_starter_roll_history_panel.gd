extends GutTest

func _create_history_panel() -> Control:
	var scene: PackedScene = load("res://scenes/features/life_tracker/components/dice_roll/starter_roll_history_panel.tscn")
	var panel: Control = scene.instantiate()
	add_child_autofree(panel)
	return panel

func _build_players() -> Array[Dictionary]:
	return [
		{"player_index": 0, "player_name": "Player 1", "player_color": Color(0.86, 0.26, 0.26, 1.0)},
		{"player_index": 1, "player_name": "Player 2", "player_color": Color(0.22, 0.58, 0.92, 1.0)},
		{"player_index": 2, "player_name": "Player 3", "player_color": Color(0.20, 0.72, 0.40, 1.0)},
		{"player_index": 3, "player_name": "Player 4", "player_color": Color(0.95, 0.62, 0.18, 1.0)}
	]

func test_show_history_creates_one_die_per_player() -> void:
	var panel: Control = _create_history_panel()
	var round_results: Dictionary = {"0": 6, "1": 6, "2": 4, "3": 2}
	panel.call("show_history", _build_players(), round_results)
	assert_eq(int(panel.call("get_history_dice_count")), 4)

func test_clear_history_hides_panel() -> void:
	var panel: Control = _create_history_panel()
	var round_results: Dictionary = {"0": 6, "1": 6, "2": 4, "3": 2}
	panel.call("show_history", _build_players(), round_results)
	panel.call("clear_history")
	assert_false(panel.visible)

func test_show_history_expands_width_for_four_dice() -> void:
	var panel: Control = _create_history_panel()
	var round_results: Dictionary = {"0": 6, "1": 6, "2": 4, "3": 2}
	panel.call("show_history", _build_players(), round_results)
	assert_true(panel.size.x >= 567.0)
