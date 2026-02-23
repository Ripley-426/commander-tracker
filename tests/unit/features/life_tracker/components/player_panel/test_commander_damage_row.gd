extends GutTest

var last_source_player_index: int = -1
var last_delta: int = 0
var total_delta: int = 0

func _on_delta_requested(source_player_index: int, delta: int) -> void:
	last_source_player_index = source_player_index
	last_delta = delta
	total_delta += delta

func before_each() -> void:
	last_source_player_index = -1
	last_delta = 0
	total_delta = 0

func _create_row() -> Control:
	var scene: PackedScene = load("res://scenes/features/life_tracker/components/player_panel/commander_damage_row.tscn")
	var row: Control = scene.instantiate()
	add_child_autofree(row)
	return row

func _tap_button(button: Button) -> void:
	button.button_down.emit()
	button.button_up.emit()

func test_setup_sets_damage_text() -> void:
	var row: Control = _create_row()
	row.call("setup", 3, 4, Color(0.8, 0.2, 0.2, 1.0))

	var damage_label: Label = row.get_node("DamageLabel")
	assert_eq(damage_label.text, "4")

func test_setup_applies_plus_button_color() -> void:
	var row: Control = _create_row()
	var source_color: Color = Color(0.8, 0.2, 0.2, 1.0)
	row.call("setup", 3, 4, source_color)

	var plus_button: Button = row.get_node("PlusButton")
	var plus_style: StyleBoxFlat = plus_button.get_theme_stylebox("normal") as StyleBoxFlat
	assert_eq(plus_style.bg_color, source_color)

func test_plus_button_tap_emits_positive_delta() -> void:
	var row: Control = _create_row()
	row.connect("delta_requested", Callable(self, "_on_delta_requested"))
	row.call("setup", 1, 0, Color(0.2, 0.4, 0.8, 1.0))

	var plus_button: Button = row.get_node("PlusButton")
	_tap_button(plus_button)
	assert_eq(last_source_player_index, 1)
	assert_eq(last_delta, 1)

func test_minus_button_tap_emits_negative_delta() -> void:
	var row: Control = _create_row()
	row.connect("delta_requested", Callable(self, "_on_delta_requested"))
	row.call("setup", 1, 0, Color(0.2, 0.4, 0.8, 1.0))

	var minus_button: Button = row.get_node("MinusButton")
	_tap_button(minus_button)
	assert_eq(last_source_player_index, 1)
	assert_eq(last_delta, -1)

func test_hold_after_one_second_emits_plus_ten() -> void:
	var row: Control = _create_row()
	row.connect("delta_requested", Callable(self, "_on_delta_requested"))
	row.call("setup", 1, 0, Color(0.2, 0.4, 0.8, 1.0))

	var plus_button: Button = row.get_node("PlusButton")
	plus_button.button_down.emit()
	plus_button.call("_on_hold_repeat_timeout")
	assert_eq(last_delta, 10)

func test_hold_repeat_emits_ten_each_timeout() -> void:
	var row: Control = _create_row()
	row.connect("delta_requested", Callable(self, "_on_delta_requested"))
	row.call("setup", 1, 0, Color(0.2, 0.4, 0.8, 1.0))

	var minus_button: Button = row.get_node("MinusButton")
	minus_button.button_down.emit()
	minus_button.call("_on_hold_repeat_timeout")
	minus_button.call("_on_hold_repeat_timeout")
	assert_eq(total_delta, -20)

func test_hold_release_after_repeat_does_not_emit_single_tap_delta() -> void:
	var row: Control = _create_row()
	row.connect("delta_requested", Callable(self, "_on_delta_requested"))
	row.call("setup", 1, 0, Color(0.2, 0.4, 0.8, 1.0))

	var plus_button: Button = row.get_node("PlusButton")
	plus_button.button_down.emit()
	plus_button.call("_on_hold_repeat_timeout")
	plus_button.button_up.emit()
	assert_eq(total_delta, 10)

func test_hold_repeat_timer_uses_one_second() -> void:
	var row: Control = _create_row()
	var plus_button: Button = row.get_node("PlusButton")
	var hold_repeat_timer: Timer = plus_button.get_node("HoldRepeatTimer")
	assert_eq(hold_repeat_timer.wait_time, 1.0)

func test_set_damage_clamps_to_zero() -> void:
	var row: Control = _create_row()
	row.call("setup", 0, 2, Color(0.3, 0.7, 0.2, 1.0))
	row.call("set_damage", -7)

	var damage_label: Label = row.get_node("DamageLabel")
	assert_eq(damage_label.text, "0")

func test_minus_button_meets_mobile_touch_size() -> void:
	var row: Control = _create_row()
	row.call("setup", 0, 2, Color(0.3, 0.7, 0.2, 1.0))

	var minus_button: Button = row.get_node("MinusButton")
	assert_true(minus_button.custom_minimum_size.x >= 52.0)

func test_plus_button_meets_mobile_touch_size() -> void:
	var row: Control = _create_row()
	row.call("setup", 0, 2, Color(0.3, 0.7, 0.2, 1.0))

	var plus_button: Button = row.get_node("PlusButton")
	assert_true(plus_button.custom_minimum_size.y >= 52.0)

func test_damage_label_font_size_is_mobile_readable() -> void:
	var row: Control = _create_row()
	row.call("setup", 0, 2, Color(0.3, 0.7, 0.2, 1.0))

	var damage_label: Label = row.get_node("DamageLabel")
	assert_true(int(damage_label.get("theme_override_font_sizes/font_size")) >= 32)
