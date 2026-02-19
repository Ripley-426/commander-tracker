extends GutTest

var last_source_player_index: int = -1
var last_delta: int = 0

func _on_delta_requested(source_player_index: int, delta: int) -> void:
	last_source_player_index = source_player_index
	last_delta = delta

func before_each() -> void:
	last_source_player_index = -1
	last_delta = 0

func test_setup_applies_damage_and_color() -> void:
	var scene: PackedScene = load("res://scenes/features/life_tracker/components/commander_damage_row.tscn")
	var row: Control = scene.instantiate()
	add_child_autofree(row)

	var source_color: Color = Color(0.8, 0.2, 0.2, 1.0)
	row.call("setup", 3, 4, source_color)

	var damage_label: Label = row.get_node("DamageLabel")
	assert_eq(damage_label.text, "4")

	var plus_button: Button = row.get_node("PlusButton")
	var plus_style: StyleBoxFlat = plus_button.get_theme_stylebox("normal") as StyleBoxFlat
	assert_eq(plus_style.bg_color, source_color)

func test_buttons_emit_delta_requested() -> void:
	var scene: PackedScene = load("res://scenes/features/life_tracker/components/commander_damage_row.tscn")
	var row: Control = scene.instantiate()
	add_child_autofree(row)
	row.connect("delta_requested", Callable(self, "_on_delta_requested"))
	row.call("setup", 1, 0, Color(0.2, 0.4, 0.8, 1.0))

	var plus_button: Button = row.get_node("PlusButton")
	var minus_button: Button = row.get_node("MinusButton")

	plus_button.pressed.emit()
	assert_eq(last_source_player_index, 1)
	assert_eq(last_delta, 1)

	minus_button.pressed.emit()
	assert_eq(last_source_player_index, 1)
	assert_eq(last_delta, -1)

func test_set_damage_clamps_to_zero() -> void:
	var scene: PackedScene = load("res://scenes/features/life_tracker/components/commander_damage_row.tscn")
	var row: Control = scene.instantiate()
	add_child_autofree(row)
	row.call("setup", 0, 2, Color(0.3, 0.7, 0.2, 1.0))
	row.call("set_damage", -7)

	var damage_label: Label = row.get_node("DamageLabel")
	assert_eq(damage_label.text, "0")

