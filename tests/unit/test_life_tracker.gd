extends GutTest

class FakeStore extends RefCounted:
	var active_state: Dictionary = {}
	var save_calls: int = 0

	func _init(p_state: Dictionary = {}) -> void:
		active_state = p_state.duplicate(true)

	func load_active_game() -> Dictionary:
		return active_state.duplicate(true)

	func save_active_game(state: Dictionary) -> bool:
		save_calls += 1
		active_state = state.duplicate(true)
		return true

func test_ready_renders_settings_from_loaded_state() -> void:
	var state: Dictionary = GameState.create_new_game(2, 40, "p2_head_to_head")
	var fake_store: FakeStore = FakeStore.new(state)

	var scene: PackedScene = load("res://scenes/life_tracker.tscn")
	var tracker: Control = scene.instantiate()
	var service_script: GDScript = load("res://scripts/game_session_service.gd")
	tracker.store = fake_store
	tracker.session_service = service_script.new(fake_store)
	add_child_autofree(tracker)

	var board_container: Control = tracker.get_node("VBoxContainer/BoardContainer")
	assert_eq(board_container.get_child_count(), 2)

func test_life_delta_updates_state_and_saves() -> void:
	var state: Dictionary = GameState.create_new_game(2, 40, "p2_head_to_head")
	var fake_store: FakeStore = FakeStore.new(state)

	var scene: PackedScene = load("res://scenes/life_tracker.tscn")
	var tracker: Control = scene.instantiate()
	var service_script: GDScript = load("res://scripts/game_session_service.gd")
	tracker.store = fake_store
	tracker.session_service = service_script.new(fake_store)
	add_child_autofree(tracker)

	var board_container: Control = tracker.get_node("VBoxContainer/BoardContainer")
	var first_panel: Control = board_container.get_child(0)
	first_panel.call("tap_at_normalized_y", 0.10)

	var players: Array = tracker.game_state.get("players", [])
	var player0: Dictionary = players[0]
	assert_eq(player0.get("life", 0), 41)
	assert_true(fake_store.save_calls > 0)

func test_first_two_player_panels_are_rotated_180_degrees() -> void:
	var state: Dictionary = GameState.create_new_game(4, 40, "p4_two_facing_two")
	var fake_store: FakeStore = FakeStore.new(state)

	var scene: PackedScene = load("res://scenes/life_tracker.tscn")
	var tracker: Control = scene.instantiate()
	var service_script: GDScript = load("res://scripts/game_session_service.gd")
	tracker.store = fake_store
	tracker.session_service = service_script.new(fake_store)
	add_child_autofree(tracker)

	var board_container: Control = tracker.get_node("VBoxContainer/BoardContainer")
	var panel_1: Control = board_container.get_child(0)
	var panel_2: Control = board_container.get_child(1)
	var panel_3: Control = board_container.get_child(2)

	assert_eq(panel_1.rotation_degrees, 180.0)
	assert_eq(panel_2.rotation_degrees, 180.0)
	assert_eq(panel_3.rotation_degrees, 0.0)
