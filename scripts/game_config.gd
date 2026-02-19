extends Control

@onready var player_count_spinbox: SpinBox = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/PlayerCountSpinBox
@onready var starting_life_spinbox: SpinBox = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/StartingLifeSpinBox
@onready var layout_option_button: OptionButton = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/LayoutOptionButton
@onready var start_button: Button = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/ButtonsRow/StartButton
@onready var back_button: Button = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/ButtonsRow/BackButton

var store: RefCounted = PersistenceStore.new()
var current_layouts: Array[Dictionary] = []
var on_open_life_tracker: Callable = Callable()
var on_open_main_menu: Callable = Callable()

func _ready() -> void:
	player_count_spinbox.min_value = 2
	player_count_spinbox.max_value = 6
	player_count_spinbox.step = 1
	player_count_spinbox.value = 4

	starting_life_spinbox.min_value = 1
	starting_life_spinbox.max_value = 999
	starting_life_spinbox.step = 1
	starting_life_spinbox.value = 40

	player_count_spinbox.value_changed.connect(_on_player_count_changed)
	start_button.pressed.connect(_on_start_pressed)
	back_button.pressed.connect(_on_back_pressed)

	_refresh_layouts()

func _on_player_count_changed(_value: float) -> void:
	_refresh_layouts()

func _refresh_layouts() -> void:
	var count: int = int(player_count_spinbox.value)
	current_layouts = GameState.get_layout_presets(count)

	layout_option_button.clear()
	for i in range(current_layouts.size()):
		layout_option_button.add_item(current_layouts[i]["name"], i)
	if current_layouts.size() > 0:
		layout_option_button.selected = 0

func _on_start_pressed() -> void:
	if current_layouts.is_empty():
		return

	var layout: Dictionary = current_layouts[layout_option_button.selected]
	var state: Dictionary = GameState.create_new_game(
		int(player_count_spinbox.value),
		int(starting_life_spinbox.value),
		str(layout["id"])
	)

	var ok: bool = store.save_active_game(state)
	if ok:
		_open_life_tracker()
	else:
		push_error("Could not save game before opening tracker.")

func _on_back_pressed() -> void:
	_open_main_menu()

func _open_life_tracker() -> void:
	if on_open_life_tracker.is_valid():
		on_open_life_tracker.call()
		return
	get_tree().change_scene_to_file("res://scenes/life_tracker.tscn")

func _open_main_menu() -> void:
	if on_open_main_menu.is_valid():
		on_open_main_menu.call()
		return
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
