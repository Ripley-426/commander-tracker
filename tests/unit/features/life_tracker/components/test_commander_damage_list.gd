extends GutTest

var last_source_player_index: int = -1
var last_delta: int = 0

func _on_delta_requested(source_player_index: int, delta: int) -> void:
	last_source_player_index = source_player_index
	last_delta = delta

func before_each() -> void:
	last_source_player_index = -1
	last_delta = 0

func _create_list() -> Control:
	var scene: PackedScene = load("res://scenes/features/life_tracker/components/commander_damage_list.tscn")
	var list: Control = scene.instantiate()
	add_child_autofree(list)
	return list

func _build_rows() -> Array[Dictionary]:
	return [
		{"source_index": 0, "damage": 3, "source_color": Color(0.8, 0.2, 0.2, 1.0)},
		{"source_index": 2, "damage": 1, "source_color": Color(0.2, 0.4, 0.9, 1.0)}
	]

func test_setup_rows_creates_one_row_per_source() -> void:
	var list: Control = _create_list()
	list.call("setup_rows", _build_rows(), false)

	var container: VBoxContainer = list.get_node("CommanderDamageList")
	assert_eq(container.get_child_count(), 2)

func test_setup_rows_with_no_sources_hides_the_list() -> void:
	var list: Control = _create_list()
	var no_rows: Array[Dictionary] = []
	list.call("setup_rows", no_rows, false)

	var container: VBoxContainer = list.get_node("CommanderDamageList")
	assert_false(container.visible)

func test_set_damage_updates_matching_row_label() -> void:
	var list: Control = _create_list()
	list.call("setup_rows", _build_rows(), false)
	list.call("set_damage", 2, 7)

	var row: HBoxContainer = list.get_node("CommanderDamageList/Source_2")
	var label: Label = row.get_node("DamageLabel")
	assert_eq(label.text, "7")

func test_set_interactable_false_disables_commander_plus_button() -> void:
	var list: Control = _create_list()
	list.call("setup_rows", _build_rows(), false)
	list.call("set_interactable", false)

	var row: HBoxContainer = list.get_node("CommanderDamageList/Source_0")
	var plus_button: Button = row.get_node("PlusButton")
	assert_true(plus_button.disabled)

func test_set_interactable_true_enables_commander_plus_button() -> void:
	var list: Control = _create_list()
	list.call("setup_rows", _build_rows(), false)
	list.call("set_interactable", false)
	list.call("set_interactable", true)

	var row: HBoxContainer = list.get_node("CommanderDamageList/Source_0")
	var plus_button: Button = row.get_node("PlusButton")
	assert_false(plus_button.disabled)

func test_row_delta_is_forwarded_by_list_signal() -> void:
	var list: Control = _create_list()
	list.connect("delta_requested", Callable(self, "_on_delta_requested"))
	list.call("setup_rows", _build_rows(), false)

	var row: HBoxContainer = list.get_node("CommanderDamageList/Source_0")
	var plus_button: Button = row.get_node("PlusButton")
	plus_button.button_down.emit()
	plus_button.button_up.emit()
	assert_eq(last_delta, 1)
