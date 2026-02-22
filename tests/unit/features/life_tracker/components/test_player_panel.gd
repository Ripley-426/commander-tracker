extends GutTest

var last_player_index: int = -1
var last_delta: int = 0
var total_life_delta: int = 0
var last_commander_target_player_index: int = -1
var last_commander_source_player_index: int = -1
var last_commander_delta: int = 0

func _on_life_delta_requested(player_index: int, delta: int) -> void:
	last_player_index = player_index
	last_delta = delta
	total_life_delta += delta

func _on_commander_delta_requested(target_player_index: int, source_player_index: int, delta: int) -> void:
	last_commander_target_player_index = target_player_index
	last_commander_source_player_index = source_player_index
	last_commander_delta = delta

func before_each() -> void:
	last_player_index = -1
	last_delta = 0
	total_life_delta = 0
	last_commander_target_player_index = -1
	last_commander_source_player_index = -1
	last_commander_delta = 0

func _tap_life_button(button: Button) -> void:
	button.button_down.emit()
	button.button_up.emit()

func _tap_commander_button(button: Button) -> void:
	button.button_down.emit()
	button.button_up.emit()

func _create_panel() -> Control:
	var scene: PackedScene = load("res://scenes/features/life_tracker/components/player_panel.tscn")
	var panel: Control = scene.instantiate()
	add_child_autofree(panel)
	return panel

func test_setup_sets_player_name_text() -> void:
	var panel: Control = _create_panel()
	panel.call("setup", 2, "Player 3", 40, Color(1.0, 0.0, 0.0, 1.0))

	var name_label: Label = panel.get_node("HeaderArea/NameLabel")
	assert_eq(name_label.text, "Player 3")

func test_setup_sets_life_text() -> void:
	var panel: Control = _create_panel()
	panel.call("setup", 2, "Player 3", 40, Color(1.0, 0.0, 0.0, 1.0))

	var life_label: Label = panel.get_node("MiddleArea/LifeLabel")
	assert_eq(life_label.text, "40")

func test_name_label_is_top_anchored() -> void:
	var panel: Control = _create_panel()
	panel.call("setup", 2, "Player 3", 40, Color(1.0, 0.0, 0.0, 1.0))

	var name_label: Label = panel.get_node("HeaderArea/NameLabel")
	assert_true(is_equal_approx(name_label.anchor_top, 0.0))

func test_top_tap_emits_plus_one_life_delta() -> void:
	var panel: Control = _create_panel()
	panel.connect("life_delta_requested", Callable(self, "_on_life_delta_requested"))
	panel.call("setup", 2, "Player 3", 40, Color(1.0, 0.0, 0.0, 1.0))

	var top_hit_button: Button = panel.get_node("HitZones/TopHitButton")
	_tap_life_button(top_hit_button)
	assert_eq(last_player_index, 2)
	assert_eq(last_delta, 1)

func test_bottom_tap_emits_minus_one_life_delta() -> void:
	var panel: Control = _create_panel()
	panel.connect("life_delta_requested", Callable(self, "_on_life_delta_requested"))
	panel.call("setup", 2, "Player 3", 40, Color(1.0, 0.0, 0.0, 1.0))

	var bottom_hit_button: Button = panel.get_node("HitZones/BottomHitButton")
	_tap_life_button(bottom_hit_button)
	assert_eq(last_player_index, 2)
	assert_eq(last_delta, -1)

func test_rotated_panel_top_tap_still_emits_plus_one() -> void:
	var panel: Control = _create_panel()
	panel.connect("life_delta_requested", Callable(self, "_on_life_delta_requested"))
	panel.call("setup", 0, "Player 1", 40, Color(1.0, 0.0, 0.0, 1.0), true)

	var top_hit_button: Button = panel.get_node("HitZones/TopHitButton")
	_tap_life_button(top_hit_button)
	assert_eq(last_player_index, 0)
	assert_eq(last_delta, 1)

func test_rotated_panel_bottom_tap_still_emits_minus_one() -> void:
	var panel: Control = _create_panel()
	panel.connect("life_delta_requested", Callable(self, "_on_life_delta_requested"))
	panel.call("setup", 0, "Player 1", 40, Color(1.0, 0.0, 0.0, 1.0), true)

	var bottom_hit_button: Button = panel.get_node("HitZones/BottomHitButton")
	_tap_life_button(bottom_hit_button)
	assert_eq(last_player_index, 0)
	assert_eq(last_delta, -1)

func test_life_font_size_has_mobile_minimum() -> void:
	var panel: Control = _create_panel()
	panel.call("setup", 1, "Player 2", 40, Color(0.0, 0.4, 1.0, 1.0))
	panel.size = Vector2(100.0, 200.0)
	panel.call("_refresh_dynamic_text_size")

	var life_label: Label = panel.get_node("MiddleArea/LifeLabel")
	var font_size: int = int(life_label.get("theme_override_font_sizes/font_size"))
	assert_true(font_size >= 84)

func test_life_font_size_scales_with_panel_height() -> void:
	var panel: Control = _create_panel()
	panel.call("setup", 1, "Player 2", 40, Color(0.0, 0.4, 1.0, 1.0))
	panel.size = Vector2(100.0, 200.0)
	panel.call("_refresh_dynamic_text_size")
	var life_label: Label = panel.get_node("MiddleArea/LifeLabel")
	var small_size: int = int(life_label.get("theme_override_font_sizes/font_size"))

	panel.size = Vector2(100.0, 500.0)
	panel.call("_refresh_dynamic_text_size")
	var large_size: int = int(life_label.get("theme_override_font_sizes/font_size"))
	assert_true(large_size > small_size)

func test_hit_zone_button_has_pressed_feedback_style() -> void:
	var panel: Control = _create_panel()
	panel.call("setup", 1, "Player 2", 40, Color(0.0, 0.4, 1.0, 1.0))

	var top_hit_button: Button = panel.get_node("HitZones/TopHitButton")
	var normal_style: StyleBoxFlat = top_hit_button.get_theme_stylebox("normal") as StyleBoxFlat
	var pressed_style: StyleBoxFlat = top_hit_button.get_theme_stylebox("pressed") as StyleBoxFlat

	assert_not_null(normal_style)
	assert_not_null(pressed_style)
	assert_true(pressed_style.bg_color.a > normal_style.bg_color.a)

func test_delta_label_accumulates_life_changes() -> void:
	var panel: Control = _create_panel()
	panel.call("setup", 1, "Player 2", 40, Color(0.0, 0.4, 1.0, 1.0))

	var top_hit_button: Button = panel.get_node("HitZones/TopHitButton")
	var bottom_hit_button: Button = panel.get_node("HitZones/BottomHitButton")
	var delta_label: Label = panel.get_node("MiddleArea/DeltaLabel")

	_tap_life_button(top_hit_button)
	_tap_life_button(top_hit_button)
	_tap_life_button(bottom_hit_button)
	assert_true(delta_label.visible)
	assert_eq(delta_label.text, "+1")

func test_delta_label_resets_after_timeout() -> void:
	var panel: Control = _create_panel()
	panel.call("setup", 1, "Player 2", 40, Color(0.0, 0.4, 1.0, 1.0))

	var top_hit_button: Button = panel.get_node("HitZones/TopHitButton")
	var delta_label: Label = panel.get_node("MiddleArea/DeltaLabel")

	_tap_life_button(top_hit_button)
	panel.call("_on_delta_reset_timeout")
	assert_false(delta_label.visible)
	assert_eq(delta_label.text, "+0")

func test_setup_builds_expected_commander_row_count() -> void:
	var panel: Control = _create_panel()
	var commander_rows: Array[Dictionary] = [
		{"source_index": 0, "source_name": "Player 1", "damage": 2, "source_color": Color(0.8, 0.2, 0.2, 1.0)},
		{"source_index": 2, "source_name": "Player 3", "damage": 5, "source_color": Color(0.2, 0.4, 0.9, 1.0)}
	]
	panel.call("setup", 1, "Player 2", 40, Color(0.0, 0.4, 1.0, 1.0), false, commander_rows)

	var commander_container: VBoxContainer = panel.get_node("CommanderDamageContainer/CommanderDamageList")
	assert_eq(commander_container.get_child_count(), 2)

func test_setup_applies_initial_commander_damage_value() -> void:
	var panel: Control = _create_panel()
	var commander_rows: Array[Dictionary] = [
		{"source_index": 0, "source_name": "Player 1", "damage": 2, "source_color": Color(0.8, 0.2, 0.2, 1.0)}
	]
	panel.call("setup", 1, "Player 2", 40, Color(0.0, 0.4, 1.0, 1.0), false, commander_rows)

	var row: HBoxContainer = panel.get_node("CommanderDamageContainer/CommanderDamageList/Source_0")
	var damage_label: Label = row.get_node("DamageLabel")
	assert_eq(damage_label.text, "2")

func test_setup_applies_commander_button_color() -> void:
	var panel: Control = _create_panel()
	var source_color: Color = Color(0.8, 0.2, 0.2, 1.0)
	var commander_rows: Array[Dictionary] = [
		{"source_index": 0, "source_name": "Player 1", "damage": 2, "source_color": source_color}
	]
	panel.call("setup", 1, "Player 2", 40, Color(0.0, 0.4, 1.0, 1.0), false, commander_rows)

	var row: HBoxContainer = panel.get_node("CommanderDamageContainer/CommanderDamageList/Source_0")
	var plus_button: Button = row.get_node("PlusButton")
	var plus_style: StyleBoxFlat = plus_button.get_theme_stylebox("normal") as StyleBoxFlat
	assert_eq(plus_style.bg_color, source_color)

func test_commander_plus_button_emits_positive_delta() -> void:
	var panel: Control = _create_panel()
	panel.connect("commander_delta_requested", Callable(self, "_on_commander_delta_requested"))
	var commander_rows: Array[Dictionary] = [
		{"source_index": 0, "source_name": "Player 1", "damage": 2, "source_color": Color(0.8, 0.2, 0.2, 1.0)}
	]
	panel.call("setup", 1, "Player 2", 40, Color(0.0, 0.4, 1.0, 1.0), false, commander_rows)

	var row: HBoxContainer = panel.get_node("CommanderDamageContainer/CommanderDamageList/Source_0")
	var plus_button: Button = row.get_node("PlusButton")
	_tap_commander_button(plus_button)
	assert_eq(last_commander_target_player_index, 1)
	assert_eq(last_commander_source_player_index, 0)
	assert_eq(last_commander_delta, 1)

func test_commander_minus_button_emits_negative_delta() -> void:
	var panel: Control = _create_panel()
	panel.connect("commander_delta_requested", Callable(self, "_on_commander_delta_requested"))
	var commander_rows: Array[Dictionary] = [
		{"source_index": 0, "source_name": "Player 1", "damage": 2, "source_color": Color(0.8, 0.2, 0.2, 1.0)}
	]
	panel.call("setup", 1, "Player 2", 40, Color(0.0, 0.4, 1.0, 1.0), false, commander_rows)

	var row: HBoxContainer = panel.get_node("CommanderDamageContainer/CommanderDamageList/Source_0")
	var minus_button: Button = row.get_node("MinusButton")
	_tap_commander_button(minus_button)
	assert_eq(last_commander_delta, -1)

func test_hold_after_one_second_emits_ten() -> void:
	var panel: Control = _create_panel()
	panel.connect("life_delta_requested", Callable(self, "_on_life_delta_requested"))
	panel.call("setup", 1, "Player 2", 40, Color(0.0, 0.4, 1.0, 1.0))

	var top_hit_button: Button = panel.get_node("HitZones/TopHitButton")
	top_hit_button.button_down.emit()
	top_hit_button.call("_on_hold_repeat_timeout")
	assert_eq(last_delta, 10)

func test_hold_release_after_repeat_does_not_emit_single_tap_delta() -> void:
	var panel: Control = _create_panel()
	panel.connect("life_delta_requested", Callable(self, "_on_life_delta_requested"))
	panel.call("setup", 1, "Player 2", 40, Color(0.0, 0.4, 1.0, 1.0))

	var top_hit_button: Button = panel.get_node("HitZones/TopHitButton")
	top_hit_button.button_down.emit()
	top_hit_button.call("_on_hold_repeat_timeout")
	top_hit_button.button_up.emit()
	assert_eq(total_life_delta, 10)

func test_hold_repeat_emits_ten_each_timeout() -> void:
	var panel: Control = _create_panel()
	panel.connect("life_delta_requested", Callable(self, "_on_life_delta_requested"))
	panel.call("setup", 4, "Player 5", 40, Color(0.0, 0.4, 1.0, 1.0))

	var bottom_hit_button: Button = panel.get_node("HitZones/BottomHitButton")
	bottom_hit_button.button_down.emit()
	bottom_hit_button.call("_on_hold_repeat_timeout")
	bottom_hit_button.call("_on_hold_repeat_timeout")
	assert_eq(total_life_delta, -20)

func test_hold_repeat_timer_uses_one_second() -> void:
	var panel: Control = _create_panel()
	var top_hit_button: Button = panel.get_node("HitZones/TopHitButton")
	var hold_repeat_timer: Timer = top_hit_button.get_node("HoldRepeatTimer")
	assert_eq(hold_repeat_timer.wait_time, 1.0)

func test_life_label_has_horizontal_padding() -> void:
	var panel: Control = _create_panel()
	var life_label: Label = panel.get_node("MiddleArea/LifeLabel")
	assert_true(life_label.offset_left > 0.0)
	assert_true(life_label.offset_right < 0.0)

func test_delta_label_has_horizontal_padding() -> void:
	var panel: Control = _create_panel()
	var delta_label: Label = panel.get_node("MiddleArea/DeltaLabel")
	assert_true(delta_label.offset_left > 0.0)
	assert_true(delta_label.offset_right < 0.0)

func test_dead_button_is_anchored_to_bottom_right() -> void:
	var panel: Control = _create_panel()
	var dead_button: Button = panel.get_node("DeadButton")
	assert_true(is_equal_approx(dead_button.anchor_left, 1.0))
	assert_true(is_equal_approx(dead_button.anchor_top, 1.0))

func test_dead_button_press_desaturates_panel_color() -> void:
	var panel: Control = _create_panel()
	panel.call("setup", 1, "Player 2", 40, Color(0.86, 0.26, 0.26, 1.0))

	var before_style: StyleBoxFlat = panel.get_theme_stylebox("panel") as StyleBoxFlat
	var before_color: Color = before_style.bg_color
	var dead_button: Button = panel.get_node("DeadButton")
	dead_button.pressed.emit()

	var after_style: StyleBoxFlat = panel.get_theme_stylebox("panel") as StyleBoxFlat
	var after_color: Color = after_style.bg_color
	assert_true(after_color.s < before_color.s)

func test_dead_button_press_disables_life_buttons() -> void:
	var panel: Control = _create_panel()
	panel.call("setup", 1, "Player 2", 40, Color(0.86, 0.26, 0.26, 1.0))

	var dead_button: Button = panel.get_node("DeadButton")
	dead_button.pressed.emit()
	var top_hit_button: Button = panel.get_node("HitZones/TopHitButton")
	var bottom_hit_button: Button = panel.get_node("HitZones/BottomHitButton")
	assert_true(top_hit_button.disabled)
	assert_true(bottom_hit_button.disabled)

func test_dead_button_second_press_restores_life_button_interactivity() -> void:
	var panel: Control = _create_panel()
	panel.call("setup", 1, "Player 2", 40, Color(0.86, 0.26, 0.26, 1.0))

	var dead_button: Button = panel.get_node("DeadButton")
	dead_button.pressed.emit()
	dead_button.pressed.emit()
	var top_hit_button: Button = panel.get_node("HitZones/TopHitButton")
	var bottom_hit_button: Button = panel.get_node("HitZones/BottomHitButton")
	assert_false(top_hit_button.disabled)
	assert_false(bottom_hit_button.disabled)

func test_dead_button_press_disables_commander_buttons() -> void:
	var panel: Control = _create_panel()
	var commander_rows: Array[Dictionary] = [
		{"source_index": 0, "source_name": "Player 1", "damage": 2, "source_color": Color(0.8, 0.2, 0.2, 1.0)}
	]
	panel.call("setup", 1, "Player 2", 40, Color(0.0, 0.4, 1.0, 1.0), false, commander_rows)

	var dead_button: Button = panel.get_node("DeadButton")
	dead_button.pressed.emit()
	var row: HBoxContainer = panel.get_node("CommanderDamageContainer/CommanderDamageList/Source_0")
	var plus_button: Button = row.get_node("PlusButton")
	var minus_button: Button = row.get_node("MinusButton")
	assert_true(plus_button.disabled)
	assert_true(minus_button.disabled)

func test_dead_button_second_press_restores_original_panel_color() -> void:
	var panel: Control = _create_panel()
	var base_color: Color = Color(0.86, 0.26, 0.26, 1.0)
	panel.call("setup", 1, "Player 2", 40, base_color)

	var dead_button: Button = panel.get_node("DeadButton")
	dead_button.pressed.emit()
	dead_button.pressed.emit()

	var restored_style: StyleBoxFlat = panel.get_theme_stylebox("panel") as StyleBoxFlat
	assert_eq(restored_style.bg_color, base_color)

