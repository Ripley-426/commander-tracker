extends GutTest

var last_player_index: int = -1
var last_delta: int = 0

func _on_life_delta_requested(player_index: int, delta: int) -> void:
	last_player_index = player_index
	last_delta = delta

func before_each() -> void:
	last_player_index = -1
	last_delta = 0

func test_setup_updates_labels_and_buttons_emit_delta() -> void:
	var scene: PackedScene = load("res://scenes/components/player_panel.tscn")
	var panel: Node = scene.instantiate()
	add_child_autofree(panel)

	panel.connect("life_delta_requested", Callable(self, "_on_life_delta_requested"))
	panel.call("setup", 2, "Player 3", 40, Color(1.0, 0.0, 0.0, 1.0))

	var name_label: Label = panel.get_node("MiddleArea/NameLabel")
	var life_label: Label = panel.get_node("MiddleArea/LifeLabel")
	assert_eq(name_label.text, "Player 3")
	assert_eq(life_label.text, "40")

	panel.call("tap_at_normalized_y", 0.10)
	assert_eq(last_player_index, 2)
	assert_eq(last_delta, 1)

	panel.call("tap_at_normalized_y", 0.90)
	assert_eq(last_player_index, 2)
	assert_eq(last_delta, -1)

func test_rotated_panel_uses_same_zone_thresholds_in_local_space() -> void:
	var scene: PackedScene = load("res://scenes/components/player_panel.tscn")
	var panel: Node = scene.instantiate()
	add_child_autofree(panel)

	panel.connect("life_delta_requested", Callable(self, "_on_life_delta_requested"))
	panel.call("setup", 0, "Player 1", 40, Color(1.0, 0.0, 0.0, 1.0), true)

	panel.call("tap_at_normalized_y", 0.10)
	assert_eq(last_player_index, 0)
	assert_eq(last_delta, 1)

	panel.call("tap_at_normalized_y", 0.90)
	assert_eq(last_player_index, 0)
	assert_eq(last_delta, -1)

func test_gui_input_tap_triggers_zone_delta() -> void:
	var scene: PackedScene = load("res://scenes/components/player_panel.tscn")
	var panel: Control = scene.instantiate()
	add_child_autofree(panel)

	panel.connect("life_delta_requested", Callable(self, "_on_life_delta_requested"))
	panel.call("setup", 1, "Player 2", 40, Color(0.0, 0.4, 1.0, 1.0))
	panel.size = Vector2(100.0, 200.0)

	var event: InputEventMouseButton = InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	event.position = Vector2(10.0, 20.0) # top zone
	panel._gui_input(event)

	assert_eq(last_player_index, 1)
	assert_eq(last_delta, 1)

func test_life_font_size_scales_with_panel_height() -> void:
	var scene: PackedScene = load("res://scenes/components/player_panel.tscn")
	var panel: Control = scene.instantiate()
	add_child_autofree(panel)

	panel.call("setup", 1, "Player 2", 40, Color(0.0, 0.4, 1.0, 1.0))
	panel.size = Vector2(100.0, 200.0)
	panel.call("_refresh_dynamic_text_size")
	var life_label: Label = panel.get_node("MiddleArea/LifeLabel")
	var small_size: int = int(life_label.get("theme_override_font_sizes/font_size"))

	panel.size = Vector2(100.0, 500.0)
	panel.call("_refresh_dynamic_text_size")
	var large_size: int = int(life_label.get("theme_override_font_sizes/font_size"))

	assert_true(large_size > small_size)
