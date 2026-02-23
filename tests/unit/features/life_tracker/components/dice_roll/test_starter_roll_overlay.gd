extends GutTest

func _create_overlay() -> Control:
	var scene: PackedScene = load("res://scenes/features/life_tracker/components/dice_roll/starter_roll_overlay.tscn")
	var overlay: Control = scene.instantiate()
	add_child_autofree(overlay)
	return overlay

func _build_players() -> Array[Dictionary]:
	return [
		{"player_index": 0, "player_name": "Player 1", "player_color": Color(0.86, 0.26, 0.26, 1.0)},
		{"player_index": 1, "player_name": "Player 2", "player_color": Color(0.22, 0.58, 0.92, 1.0)},
		{"player_index": 2, "player_name": "Player 3", "player_color": Color(0.20, 0.72, 0.40, 1.0)}
	]

func _build_four_players() -> Array[Dictionary]:
	return [
		{"player_index": 0, "player_name": "Player 1", "player_color": Color(0.86, 0.26, 0.26, 1.0)},
		{"player_index": 1, "player_name": "Player 2", "player_color": Color(0.22, 0.58, 0.92, 1.0)},
		{"player_index": 2, "player_name": "Player 3", "player_color": Color(0.20, 0.72, 0.40, 1.0)},
		{"player_index": 3, "player_name": "Player 4", "player_color": Color(0.95, 0.62, 0.18, 1.0)}
	]

func test_start_roll_makes_overlay_visible() -> void:
	var overlay: Control = _create_overlay()
	overlay.call("start_roll_for_players", _build_players(), false)
	assert_true(overlay.visible)

func test_center_dice_container_is_center_anchored() -> void:
	var overlay: Control = _create_overlay()
	var center_dice_container: HBoxContainer = overlay.get_node("MainPanel/PanelMargin/MainContent/CenterDiceContainer")
	assert_eq(center_dice_container.anchor_left, 0.5)
	assert_eq(center_dice_container.anchor_top, 0.5)
	assert_eq(center_dice_container.anchor_right, 0.5)
	assert_eq(center_dice_container.anchor_bottom, 0.5)

func test_hint_label_is_bottom_anchored_with_padding() -> void:
	var overlay: Control = _create_overlay()
	var hint_label: Label = overlay.get_node("MainPanel/PanelMargin/MainContent/HintLabel")
	assert_eq(hint_label.anchor_top, 1.0)
	assert_eq(hint_label.anchor_bottom, 1.0)
	assert_true(hint_label.offset_bottom < 0.0)

func test_non_animated_roll_sets_expected_winner() -> void:
	var overlay: Control = _create_overlay()
	var forced_values: Array[int] = [2, 6, 4]
	overlay.call("set_forced_roll_values", forced_values)
	overlay.call("start_roll_for_players", _build_players(), false)
	assert_eq(int(overlay.call("get_winner_player_index")), 1)

func test_tie_roll_creates_history_dice_for_previous_round() -> void:
	var overlay: Control = _create_overlay()
	var forced_values: Array[int] = [6, 6, 2, 4]
	overlay.call("set_forced_roll_values", forced_values)
	var players: Array[Dictionary] = _build_players()
	players.pop_back()
	overlay.call("start_roll_for_players", players, false)
	assert_eq(int(overlay.call("get_history_dice_count")), 2)

func test_request_close_is_blocked_before_winner() -> void:
	var overlay: Control = _create_overlay()
	overlay.call("start_roll_for_players", _build_players(), true)
	assert_false(bool(overlay.call("request_close")))

func test_request_close_succeeds_after_winner() -> void:
	var overlay: Control = _create_overlay()
	var forced_values: Array[int] = [1, 2, 3]
	overlay.call("set_forced_roll_values", forced_values)
	overlay.call("start_roll_for_players", _build_players(), false)
	assert_true(bool(overlay.call("request_close")))

func test_tie_round_delay_timer_has_longer_pause() -> void:
	var overlay: Control = _create_overlay()
	var round_delay_timer: Timer = overlay.get_node("RoundDelayTimer")
	assert_eq(round_delay_timer.wait_time, 0.9)

func test_background_tap_closes_after_winner_exists() -> void:
	var overlay: Control = _create_overlay()
	var forced_values: Array[int] = [1, 2, 3]
	overlay.call("set_forced_roll_values", forced_values)
	overlay.call("start_roll_for_players", _build_players(), false)
	var dim_layer: ColorRect = overlay.get_node("DimLayer")

	var click_event: InputEventMouseButton = InputEventMouseButton.new()
	click_event.button_index = MOUSE_BUTTON_LEFT
	click_event.pressed = true
	dim_layer.gui_input.emit(click_event)
	assert_false(overlay.visible)

func test_history_panel_width_expands_for_four_tied_dice() -> void:
	var overlay: Control = _create_overlay()
	var forced_values: Array[int] = [6, 6, 6, 6]
	overlay.call("set_forced_roll_values", forced_values)
	overlay.call("start_roll_for_players", _build_four_players(), false)

	var history_panel: PanelContainer = overlay.get_node("HistoryPanel")
	assert_true(history_panel.size.x >= 567.0)
