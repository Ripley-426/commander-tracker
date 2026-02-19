extends GutTest

class FakeStore extends "res://scripts/contracts/game_store.gd":
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
	var top_hit_button: Button = first_panel.get_node("HitZones/TopHitButton")
	top_hit_button.pressed.emit()

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

func test_life_delta_keeps_same_panel_instance_for_feedback() -> void:
	var state: Dictionary = GameState.create_new_game(2, 40, "p2_head_to_head")
	var fake_store: FakeStore = FakeStore.new(state)

	var scene: PackedScene = load("res://scenes/life_tracker.tscn")
	var tracker: Control = scene.instantiate()
	var service_script: GDScript = load("res://scripts/game_session_service.gd")
	tracker.store = fake_store
	tracker.session_service = service_script.new(fake_store)
	add_child_autofree(tracker)

	var board_container: Control = tracker.get_node("VBoxContainer/BoardContainer")
	var first_panel_before: Control = board_container.get_child(0)
	var top_hit_button: Button = first_panel_before.get_node("HitZones/TopHitButton")
	top_hit_button.pressed.emit()

	var first_panel_after: Control = board_container.get_child(0)
	assert_eq(first_panel_before, first_panel_after)

	var delta_label: Label = first_panel_after.get_node("MiddleArea/DeltaLabel")
	assert_true(delta_label.visible)
	assert_eq(delta_label.text, "+1")

func test_commander_delta_updates_target_commander_damage_and_saves() -> void:
	var state: Dictionary = GameState.create_new_game(2, 40, "p2_head_to_head")
	var fake_store: FakeStore = FakeStore.new(state)

	var scene: PackedScene = load("res://scenes/life_tracker.tscn")
	var tracker: Control = scene.instantiate()
	var service_script: GDScript = load("res://scripts/game_session_service.gd")
	tracker.store = fake_store
	tracker.session_service = service_script.new(fake_store)
	add_child_autofree(tracker)

	var board_container: Control = tracker.get_node("VBoxContainer/BoardContainer")
	var target_panel: Control = board_container.get_child(1)
	var row: HBoxContainer = target_panel.get_node("CommanderDamageContainer/CommanderDamageList/Source_0")
	var plus_button: Button = row.get_node("PlusButton")
	plus_button.pressed.emit()

	var players: Array = tracker.game_state.get("players", [])
	var target_player: Dictionary = players[1]
	var damage_map: Dictionary = target_player.get("commander_damage", {})
	assert_eq(int(damage_map.get("p1", 0)), 1)
	assert_eq(int(target_player.get("life", 0)), 39)
	assert_true(fake_store.save_calls > 0)

	var damage_label: Label = row.get_node("DamageLabel")
	assert_eq(damage_label.text, "1")
	var life_label: Label = target_panel.get_node("MiddleArea/LifeLabel")
	assert_eq(life_label.text, "39")
	var delta_label: Label = target_panel.get_node("MiddleArea/DeltaLabel")
	assert_true(delta_label.visible)
	assert_eq(delta_label.text, "-1")

func test_commander_delta_never_goes_below_zero_in_ui_and_state() -> void:
	var state: Dictionary = GameState.create_new_game(2, 40, "p2_head_to_head")
	var fake_store: FakeStore = FakeStore.new(state)

	var scene: PackedScene = load("res://scenes/life_tracker.tscn")
	var tracker: Control = scene.instantiate()
	var service_script: GDScript = load("res://scripts/game_session_service.gd")
	tracker.store = fake_store
	tracker.session_service = service_script.new(fake_store)
	add_child_autofree(tracker)

	var board_container: Control = tracker.get_node("VBoxContainer/BoardContainer")
	var target_panel: Control = board_container.get_child(1)
	var row: HBoxContainer = target_panel.get_node("CommanderDamageContainer/CommanderDamageList/Source_0")
	var minus_button: Button = row.get_node("MinusButton")
	minus_button.pressed.emit()

	var players: Array = tracker.game_state.get("players", [])
	var target_player: Dictionary = players[1]
	var damage_map: Dictionary = target_player.get("commander_damage", {})
	assert_eq(int(damage_map.get("p1", -1)), 0)
	assert_eq(int(target_player.get("life", 0)), 40)

	var damage_label: Label = row.get_node("DamageLabel")
	assert_eq(damage_label.text, "0")

func test_removing_commander_damage_restores_life_by_same_amount() -> void:
	var state: Dictionary = GameState.create_new_game(2, 40, "p2_head_to_head")
	var fake_store: FakeStore = FakeStore.new(state)

	var scene: PackedScene = load("res://scenes/life_tracker.tscn")
	var tracker: Control = scene.instantiate()
	var service_script: GDScript = load("res://scripts/game_session_service.gd")
	tracker.store = fake_store
	tracker.session_service = service_script.new(fake_store)
	add_child_autofree(tracker)

	var board_container: Control = tracker.get_node("VBoxContainer/BoardContainer")
	var target_panel: Control = board_container.get_child(1)
	var row: HBoxContainer = target_panel.get_node("CommanderDamageContainer/CommanderDamageList/Source_0")
	var plus_button: Button = row.get_node("PlusButton")
	var minus_button: Button = row.get_node("MinusButton")

	plus_button.pressed.emit()
	plus_button.pressed.emit()
	minus_button.pressed.emit()

	var players: Array = tracker.game_state.get("players", [])
	var target_player: Dictionary = players[1]
	var damage_map: Dictionary = target_player.get("commander_damage", {})
	assert_eq(int(damage_map.get("p1", 0)), 1)
	assert_eq(int(target_player.get("life", 0)), 39)

	var damage_label: Label = row.get_node("DamageLabel")
	var life_label: Label = target_panel.get_node("MiddleArea/LifeLabel")
	assert_eq(damage_label.text, "1")
	assert_eq(life_label.text, "39")
