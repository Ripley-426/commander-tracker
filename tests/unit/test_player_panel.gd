extends GutTest

var last_player_index: int = -1
var last_delta: int = 0
var last_commander_target_player_index: int = -1
var last_commander_source_player_index: int = -1
var last_commander_delta: int = 0

func _on_life_delta_requested(player_index: int, delta: int) -> void:
	last_player_index = player_index
	last_delta = delta

func _on_commander_delta_requested(target_player_index: int, source_player_index: int, delta: int) -> void:
	last_commander_target_player_index = target_player_index
	last_commander_source_player_index = source_player_index
	last_commander_delta = delta

func before_each() -> void:
	last_player_index = -1
	last_delta = 0
	last_commander_target_player_index = -1
	last_commander_source_player_index = -1
	last_commander_delta = 0

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

	var top_hit_button: Button = panel.get_node("HitZones/TopHitButton")
	var bottom_hit_button: Button = panel.get_node("HitZones/BottomHitButton")

	top_hit_button.pressed.emit()
	assert_eq(last_player_index, 2)
	assert_eq(last_delta, 1)

	bottom_hit_button.pressed.emit()
	assert_eq(last_player_index, 2)
	assert_eq(last_delta, -1)

func test_rotated_panel_buttons_emit_same_deltas() -> void:
	var scene: PackedScene = load("res://scenes/components/player_panel.tscn")
	var panel: Node = scene.instantiate()
	add_child_autofree(panel)

	panel.connect("life_delta_requested", Callable(self, "_on_life_delta_requested"))
	panel.call("setup", 0, "Player 1", 40, Color(1.0, 0.0, 0.0, 1.0), true)

	var top_hit_button: Button = panel.get_node("HitZones/TopHitButton")
	var bottom_hit_button: Button = panel.get_node("HitZones/BottomHitButton")

	top_hit_button.pressed.emit()
	assert_eq(last_player_index, 0)
	assert_eq(last_delta, 1)

	bottom_hit_button.pressed.emit()
	assert_eq(last_player_index, 0)
	assert_eq(last_delta, -1)

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

func test_hit_zone_buttons_have_pressed_feedback_style() -> void:
	var scene: PackedScene = load("res://scenes/components/player_panel.tscn")
	var panel: Control = scene.instantiate()
	add_child_autofree(panel)

	panel.call("setup", 1, "Player 2", 40, Color(0.0, 0.4, 1.0, 1.0))

	var top_hit_button: Button = panel.get_node("HitZones/TopHitButton")
	var normal_style: StyleBoxFlat = top_hit_button.get_theme_stylebox("normal") as StyleBoxFlat
	var pressed_style: StyleBoxFlat = top_hit_button.get_theme_stylebox("pressed") as StyleBoxFlat

	assert_not_null(normal_style)
	assert_not_null(pressed_style)
	assert_true(pressed_style.bg_color.a > normal_style.bg_color.a)

func test_delta_label_accumulates_and_resets_after_timeout() -> void:
	var scene: PackedScene = load("res://scenes/components/player_panel.tscn")
	var panel: Control = scene.instantiate()
	add_child_autofree(panel)
	panel.call("setup", 1, "Player 2", 40, Color(0.0, 0.4, 1.0, 1.0))

	var top_hit_button: Button = panel.get_node("HitZones/TopHitButton")
	var bottom_hit_button: Button = panel.get_node("HitZones/BottomHitButton")
	var delta_label: Label = panel.get_node("MiddleArea/DeltaLabel")

	top_hit_button.pressed.emit()
	top_hit_button.pressed.emit()
	assert_true(delta_label.visible)
	assert_eq(delta_label.text, "+2")

	bottom_hit_button.pressed.emit()
	assert_eq(delta_label.text, "+1")

	panel.call("_on_delta_reset_timeout")
	assert_false(delta_label.visible)
	assert_eq(delta_label.text, "+0")

func test_setup_builds_commander_rows_and_buttons_emit_signal() -> void:
	var scene: PackedScene = load("res://scenes/components/player_panel.tscn")
	var panel: Control = scene.instantiate()
	add_child_autofree(panel)
	panel.connect("commander_delta_requested", Callable(self, "_on_commander_delta_requested"))

	var commander_rows: Array[Dictionary] = [
		{"source_index": 0, "source_name": "Player 1", "damage": 2, "source_color": Color(0.8, 0.2, 0.2, 1.0)},
		{"source_index": 2, "source_name": "Player 3", "damage": 5, "source_color": Color(0.2, 0.4, 0.9, 1.0)}
	]
	panel.call("setup", 1, "Player 2", 40, Color(0.0, 0.4, 1.0, 1.0), false, commander_rows)

	var commander_container: VBoxContainer = panel.get_node("CommanderDamageContainer/CommanderDamageList")
	assert_eq(commander_container.get_child_count(), 2)

	var row: HBoxContainer = commander_container.get_node("Source_0")
	var damage_label: Label = row.get_node("DamageLabel")
	var minus_button: Button = row.get_node("MinusButton")
	var plus_button: Button = row.get_node("PlusButton")
	assert_eq(damage_label.text, "2")

	var plus_style: StyleBoxFlat = plus_button.get_theme_stylebox("normal") as StyleBoxFlat
	assert_eq(plus_style.bg_color, Color(0.8, 0.2, 0.2, 1.0))

	plus_button.pressed.emit()
	assert_eq(last_commander_target_player_index, 1)
	assert_eq(last_commander_source_player_index, 0)
	assert_eq(last_commander_delta, 1)

	minus_button.pressed.emit()
	assert_eq(last_commander_delta, -1)
