extends GutTest

class FakeStore extends "res://scripts/contracts/game_store.gd":
	var last_saved_state: Dictionary = {}
	var save_called: bool = false
	var should_succeed: bool = true

	func save_active_game(state: Dictionary) -> bool:
		save_called = true
		last_saved_state = state.duplicate(true)
		return should_succeed

var did_open_tracker: bool = false

func _mark_tracker_open() -> void:
	did_open_tracker = true

func before_each() -> void:
	did_open_tracker = false

func test_refresh_layouts_updates_options_for_player_count() -> void:
	var scene: PackedScene = load("res://scenes/game_config.tscn")
	var config: Control = scene.instantiate()
	add_child_autofree(config)

	var player_count: SpinBox = config.get_node("CenterContainer/PanelContainer/MarginContainer/VBoxContainer/PlayerCountSpinBox")
	var layout_options: OptionButton = config.get_node("CenterContainer/PanelContainer/MarginContainer/VBoxContainer/LayoutOptionButton")

	player_count.value = 2
	config._on_player_count_changed(player_count.value)

	assert_eq(layout_options.item_count, 1)
	assert_eq(layout_options.get_item_text(0), "Head-to-Head")

func test_start_pressed_saves_and_uses_navigation_callback() -> void:
	var scene: PackedScene = load("res://scenes/game_config.tscn")
	var config: Control = scene.instantiate()
	add_child_autofree(config)

	var fake_store: FakeStore = FakeStore.new()
	config.store = fake_store
	config.on_open_life_tracker = Callable(self, "_mark_tracker_open")

	var player_count: SpinBox = config.get_node("CenterContainer/PanelContainer/MarginContainer/VBoxContainer/PlayerCountSpinBox")
	var starting_life: SpinBox = config.get_node("CenterContainer/PanelContainer/MarginContainer/VBoxContainer/StartingLifeSpinBox")

	player_count.value = 3
	starting_life.value = 42
	config._on_player_count_changed(player_count.value)
	config._on_start_pressed()

	assert_true(fake_store.save_called)
	assert_true(did_open_tracker)
	assert_eq(fake_store.last_saved_state["settings"]["player_count"], 3)
	assert_eq(fake_store.last_saved_state["settings"]["starting_life"], 42)
