extends GutTest

const GAME_STATE_SCRIPT: GDScript = preload("res://scripts/domain/game_state.gd")

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

func _create_tracker(initial_state: Dictionary) -> Control:
	var fake_store: FakeStore = FakeStore.new(initial_state)
	var scene: PackedScene = load("res://scenes/features/life_tracker/life_tracker.tscn")
	var tracker: Control = scene.instantiate()
	var service_script: GDScript = load("res://scripts/domain/game_session_service.gd")
	tracker.store = fake_store
	tracker.session_service = service_script.new(fake_store)
	add_child_autofree(tracker)
	return tracker

func _create_tracker_and_store(initial_state: Dictionary) -> Dictionary:
	var fake_store: FakeStore = FakeStore.new(initial_state)
	var scene: PackedScene = load("res://scenes/features/life_tracker/life_tracker.tscn")
	var tracker: Control = scene.instantiate()
	var service_script: GDScript = load("res://scripts/domain/game_session_service.gd")
	tracker.store = fake_store
	tracker.session_service = service_script.new(fake_store)
	add_child_autofree(tracker)
	return {"tracker": tracker, "store": fake_store}

func _create_tracker_from_store(fake_store: FakeStore) -> Control:
	var scene: PackedScene = load("res://scenes/features/life_tracker/life_tracker.tscn")
	var tracker: Control = scene.instantiate()
	var service_script: GDScript = load("res://scripts/domain/game_session_service.gd")
	tracker.store = fake_store
	tracker.session_service = service_script.new(fake_store)
	add_child_autofree(tracker)
	return tracker

func _tap_top_life_button(panel: Control) -> void:
	var top_hit_button: Button = panel.get_node("HitZones/TopHitButton")
	top_hit_button.button_down.emit()
	top_hit_button.button_up.emit()

func _tap_commander_button(button: Button) -> void:
	button.button_down.emit()
	button.button_up.emit()

func _get_commander_row_count(panel: Control) -> int:
	var commander_list: VBoxContainer = panel.get_node("CommanderDamageContainer/CommanderDamageList")
	return commander_list.get_child_count()

func _open_starter_roll_from_menu(tracker: Control) -> void:
	var menu_button: Button = tracker.get_node("TrackerMenuOverlay/MenuButton")
	var roll_starter_action_button: Button = tracker.get_node("TrackerMenuOverlay/MenuPanel/MenuPanelMargin/MenuActions/RollStarterActionButton")
	menu_button.pressed.emit()
	roll_starter_action_button.pressed.emit()

func test_ready_renders_expected_panel_count() -> void:
	var state: Dictionary = GAME_STATE_SCRIPT.create_new_game(2, 40, "p2_head_to_head")
	var tracker: Control = _create_tracker(state)
	var board_container: Control = tracker.get_node("VBoxContainer/BoardContainer")
	assert_eq(board_container.get_child_count(), 2)

func test_life_delta_updates_player_life_in_state() -> void:
	var state: Dictionary = GAME_STATE_SCRIPT.create_new_game(2, 40, "p2_head_to_head")
	var context: Dictionary = _create_tracker_and_store(state)
	var tracker: Control = context["tracker"]
	var board_container: Control = tracker.get_node("VBoxContainer/BoardContainer")
	var first_panel: Control = board_container.get_child(0)
	_tap_top_life_button(first_panel)

	var players: Array = tracker.game_state.get("players", [])
	var player0: Dictionary = players[0]
	assert_eq(player0.get("life", 0), 41)

func test_life_delta_saves_updated_state() -> void:
	var state: Dictionary = GAME_STATE_SCRIPT.create_new_game(2, 40, "p2_head_to_head")
	var context: Dictionary = _create_tracker_and_store(state)
	var tracker: Control = context["tracker"]
	var fake_store: FakeStore = context["store"]
	var board_container: Control = tracker.get_node("VBoxContainer/BoardContainer")
	var first_panel: Control = board_container.get_child(0)
	_tap_top_life_button(first_panel)
	assert_true(fake_store.save_calls > 0)

func test_first_panel_is_rotated_180_degrees_in_four_player_layout() -> void:
	var state: Dictionary = GAME_STATE_SCRIPT.create_new_game(4, 40, "p4_two_facing_two")
	var tracker: Control = _create_tracker(state)
	var board_container: Control = tracker.get_node("VBoxContainer/BoardContainer")
	var panel_1: Control = board_container.get_child(0)
	assert_eq(panel_1.rotation_degrees, -90.0)

func test_second_panel_is_rotated_180_degrees_in_four_player_layout() -> void:
	var state: Dictionary = GAME_STATE_SCRIPT.create_new_game(4, 40, "p4_two_facing_two")
	var tracker: Control = _create_tracker(state)
	var board_container: Control = tracker.get_node("VBoxContainer/BoardContainer")
	var panel_2: Control = board_container.get_child(1)
	assert_eq(panel_2.rotation_degrees, -90.0)

func test_third_panel_is_not_rotated_in_four_player_layout() -> void:
	var state: Dictionary = GAME_STATE_SCRIPT.create_new_game(4, 40, "p4_two_facing_two")
	var tracker: Control = _create_tracker(state)
	var board_container: Control = tracker.get_node("VBoxContainer/BoardContainer")
	var panel_3: Control = board_container.get_child(2)
	assert_eq(panel_3.rotation_degrees, 90.0)

func test_life_delta_keeps_same_panel_instance() -> void:
	var state: Dictionary = GAME_STATE_SCRIPT.create_new_game(2, 40, "p2_head_to_head")
	var tracker: Control = _create_tracker(state)
	var board_container: Control = tracker.get_node("VBoxContainer/BoardContainer")
	var first_panel_before: Control = board_container.get_child(0)
	_tap_top_life_button(first_panel_before)
	var first_panel_after: Control = board_container.get_child(0)
	assert_eq(first_panel_before, first_panel_after)

func test_life_delta_updates_feedback_label_text() -> void:
	var state: Dictionary = GAME_STATE_SCRIPT.create_new_game(2, 40, "p2_head_to_head")
	var tracker: Control = _create_tracker(state)
	var board_container: Control = tracker.get_node("VBoxContainer/BoardContainer")
	var first_panel: Control = board_container.get_child(0)
	_tap_top_life_button(first_panel)

	var delta_label: Label = first_panel.get_node("MiddleArea/DeltaLabel")
	assert_true(delta_label.visible)
	assert_eq(delta_label.text, "+1")

func test_commander_plus_updates_target_commander_damage_in_state() -> void:
	var state: Dictionary = GAME_STATE_SCRIPT.create_new_game(2, 40, "p2_head_to_head")
	var tracker: Control = _create_tracker(state)
	var board_container: Control = tracker.get_node("VBoxContainer/BoardContainer")
	var target_panel: Control = board_container.get_child(1)
	var row: HBoxContainer = target_panel.get_node("CommanderDamageContainer/CommanderDamageList/Source_0")
	var plus_button: Button = row.get_node("PlusButton")
	_tap_commander_button(plus_button)

	var players: Array = tracker.game_state.get("players", [])
	var target_player: Dictionary = players[1]
	var damage_map: Dictionary = target_player.get("commander_damage", {})
	assert_eq(int(damage_map.get("p1", 0)), 1)

func test_commander_plus_reduces_life_in_state() -> void:
	var state: Dictionary = GAME_STATE_SCRIPT.create_new_game(2, 40, "p2_head_to_head")
	var tracker: Control = _create_tracker(state)
	var board_container: Control = tracker.get_node("VBoxContainer/BoardContainer")
	var target_panel: Control = board_container.get_child(1)
	var row: HBoxContainer = target_panel.get_node("CommanderDamageContainer/CommanderDamageList/Source_0")
	var plus_button: Button = row.get_node("PlusButton")
	_tap_commander_button(plus_button)

	var players: Array = tracker.game_state.get("players", [])
	var target_player: Dictionary = players[1]
	assert_eq(int(target_player.get("life", 0)), 39)

func test_commander_plus_updates_damage_label() -> void:
	var state: Dictionary = GAME_STATE_SCRIPT.create_new_game(2, 40, "p2_head_to_head")
	var tracker: Control = _create_tracker(state)
	var board_container: Control = tracker.get_node("VBoxContainer/BoardContainer")
	var target_panel: Control = board_container.get_child(1)
	var row: HBoxContainer = target_panel.get_node("CommanderDamageContainer/CommanderDamageList/Source_0")
	var plus_button: Button = row.get_node("PlusButton")
	_tap_commander_button(plus_button)

	var damage_label: Label = row.get_node("DamageLabel")
	assert_eq(damage_label.text, "1")

func test_commander_plus_updates_life_label() -> void:
	var state: Dictionary = GAME_STATE_SCRIPT.create_new_game(2, 40, "p2_head_to_head")
	var tracker: Control = _create_tracker(state)
	var board_container: Control = tracker.get_node("VBoxContainer/BoardContainer")
	var target_panel: Control = board_container.get_child(1)
	var row: HBoxContainer = target_panel.get_node("CommanderDamageContainer/CommanderDamageList/Source_0")
	var plus_button: Button = row.get_node("PlusButton")
	_tap_commander_button(plus_button)

	var life_label: Label = target_panel.get_node("MiddleArea/LifeLabel")
	assert_eq(life_label.text, "39")

func test_commander_plus_updates_delta_label() -> void:
	var state: Dictionary = GAME_STATE_SCRIPT.create_new_game(2, 40, "p2_head_to_head")
	var tracker: Control = _create_tracker(state)
	var board_container: Control = tracker.get_node("VBoxContainer/BoardContainer")
	var target_panel: Control = board_container.get_child(1)
	var row: HBoxContainer = target_panel.get_node("CommanderDamageContainer/CommanderDamageList/Source_0")
	var plus_button: Button = row.get_node("PlusButton")
	_tap_commander_button(plus_button)

	var delta_label: Label = target_panel.get_node("MiddleArea/DeltaLabel")
	assert_true(delta_label.visible)
	assert_eq(delta_label.text, "-1")

func test_commander_plus_saves_state() -> void:
	var state: Dictionary = GAME_STATE_SCRIPT.create_new_game(2, 40, "p2_head_to_head")
	var context: Dictionary = _create_tracker_and_store(state)
	var tracker: Control = context["tracker"]
	var fake_store: FakeStore = context["store"]
	var board_container: Control = tracker.get_node("VBoxContainer/BoardContainer")
	var target_panel: Control = board_container.get_child(1)
	var row: HBoxContainer = target_panel.get_node("CommanderDamageContainer/CommanderDamageList/Source_0")
	var plus_button: Button = row.get_node("PlusButton")
	_tap_commander_button(plus_button)
	assert_true(fake_store.save_calls > 0)

func test_commander_plus_hold_after_one_second_adds_ten_damage() -> void:
	var state: Dictionary = GAME_STATE_SCRIPT.create_new_game(2, 40, "p2_head_to_head")
	var tracker: Control = _create_tracker(state)
	var board_container: Control = tracker.get_node("VBoxContainer/BoardContainer")
	var target_panel: Control = board_container.get_child(1)
	var row: HBoxContainer = target_panel.get_node("CommanderDamageContainer/CommanderDamageList/Source_0")
	var plus_button: Button = row.get_node("PlusButton")
	plus_button.button_down.emit()
	plus_button.call("_on_hold_repeat_timeout")

	var players: Array = tracker.game_state.get("players", [])
	var target_player: Dictionary = players[1]
	var damage_map: Dictionary = target_player.get("commander_damage", {})
	assert_eq(int(damage_map.get("p1", 0)), 10)

func test_commander_plus_hold_release_does_not_add_extra_single_damage() -> void:
	var state: Dictionary = GAME_STATE_SCRIPT.create_new_game(2, 40, "p2_head_to_head")
	var tracker: Control = _create_tracker(state)
	var board_container: Control = tracker.get_node("VBoxContainer/BoardContainer")
	var target_panel: Control = board_container.get_child(1)
	var row: HBoxContainer = target_panel.get_node("CommanderDamageContainer/CommanderDamageList/Source_0")
	var plus_button: Button = row.get_node("PlusButton")
	plus_button.button_down.emit()
	plus_button.call("_on_hold_repeat_timeout")
	plus_button.button_up.emit()

	var players: Array = tracker.game_state.get("players", [])
	var target_player: Dictionary = players[1]
	var damage_map: Dictionary = target_player.get("commander_damage", {})
	assert_eq(int(damage_map.get("p1", 0)), 10)

func test_commander_damage_caps_at_twenty_one_in_state() -> void:
	var state: Dictionary = GAME_STATE_SCRIPT.create_new_game(2, 40, "p2_head_to_head")
	var players: Array = state.get("players", [])
	var target_player: Dictionary = players[1]
	var damage_map: Dictionary = target_player.get("commander_damage", {})
	damage_map["p1"] = 20
	target_player["commander_damage"] = damage_map
	players[1] = target_player
	state["players"] = players

	var tracker: Control = _create_tracker(state)
	var board_container: Control = tracker.get_node("VBoxContainer/BoardContainer")
	var target_panel: Control = board_container.get_child(1)
	var row: HBoxContainer = target_panel.get_node("CommanderDamageContainer/CommanderDamageList/Source_0")
	var plus_button: Button = row.get_node("PlusButton")
	_tap_commander_button(plus_button)

	var next_players: Array = tracker.game_state.get("players", [])
	var next_target_player: Dictionary = next_players[1]
	var next_damage_map: Dictionary = next_target_player.get("commander_damage", {})
	assert_eq(int(next_damage_map.get("p1", 0)), 21)

func test_commander_damage_reaching_twenty_one_sets_target_panel_dead() -> void:
	var state: Dictionary = GAME_STATE_SCRIPT.create_new_game(2, 40, "p2_head_to_head")
	var players: Array = state.get("players", [])
	var target_player: Dictionary = players[1]
	var damage_map: Dictionary = target_player.get("commander_damage", {})
	damage_map["p1"] = 20
	target_player["commander_damage"] = damage_map
	players[1] = target_player
	state["players"] = players

	var tracker: Control = _create_tracker(state)
	var board_container: Control = tracker.get_node("VBoxContainer/BoardContainer")
	var target_panel: Control = board_container.get_child(1)
	var row: HBoxContainer = target_panel.get_node("CommanderDamageContainer/CommanderDamageList/Source_0")
	var plus_button: Button = row.get_node("PlusButton")
	_tap_commander_button(plus_button)

	var top_hit_button: Button = target_panel.get_node("HitZones/TopHitButton")
	assert_true(top_hit_button.disabled)

func test_marking_player_dead_removes_their_commander_row_from_others() -> void:
	var state: Dictionary = GAME_STATE_SCRIPT.create_new_game(2, 40, "p2_head_to_head")
	var tracker: Control = _create_tracker(state)
	var board_container: Control = tracker.get_node("VBoxContainer/BoardContainer")
	var source_panel: Control = board_container.get_child(0)
	var target_panel: Control = board_container.get_child(1)
	assert_eq(_get_commander_row_count(target_panel), 1)

	var dead_button: Button = source_panel.get_node("DeadButton")
	dead_button.pressed.emit()

	var refreshed_target_panel: Control = board_container.get_child(1)
	assert_eq(_get_commander_row_count(refreshed_target_panel), 0)

func test_reviving_player_restores_commander_row_for_others() -> void:
	var state: Dictionary = GAME_STATE_SCRIPT.create_new_game(2, 40, "p2_head_to_head")
	var tracker: Control = _create_tracker(state)
	var board_container: Control = tracker.get_node("VBoxContainer/BoardContainer")
	var source_panel: Control = board_container.get_child(0)
	var target_panel: Control = board_container.get_child(1)
	assert_eq(_get_commander_row_count(target_panel), 1)

	var dead_button: Button = source_panel.get_node("DeadButton")
	dead_button.pressed.emit()
	var source_panel_after_death: Control = board_container.get_child(0)
	var dead_button_after_death: Button = source_panel_after_death.get_node("DeadButton")
	dead_button_after_death.pressed.emit()

	var refreshed_target_panel: Control = board_container.get_child(1)
	assert_eq(_get_commander_row_count(refreshed_target_panel), 1)

func test_initial_render_with_twenty_one_commander_damage_marks_player_dead() -> void:
	var state: Dictionary = GAME_STATE_SCRIPT.create_new_game(2, 40, "p2_head_to_head")
	var players: Array = state.get("players", [])
	var target_player: Dictionary = players[1]
	var damage_map: Dictionary = target_player.get("commander_damage", {})
	damage_map["p1"] = 21
	target_player["commander_damage"] = damage_map
	players[1] = target_player
	state["players"] = players

	var tracker: Control = _create_tracker(state)
	var board_container: Control = tracker.get_node("VBoxContainer/BoardContainer")
	var target_panel: Control = board_container.get_child(1)
	var top_hit_button: Button = target_panel.get_node("HitZones/TopHitButton")
	assert_true(top_hit_button.disabled)

func test_revive_at_twenty_one_allows_commander_damage_reduction() -> void:
	var state: Dictionary = GAME_STATE_SCRIPT.create_new_game(2, 40, "p2_head_to_head")
	var players: Array = state.get("players", [])
	var target_player: Dictionary = players[1]
	var damage_map: Dictionary = target_player.get("commander_damage", {})
	damage_map["p1"] = 21
	target_player["commander_damage"] = damage_map
	players[1] = target_player
	state["players"] = players

	var tracker: Control = _create_tracker(state)
	var board_container: Control = tracker.get_node("VBoxContainer/BoardContainer")
	var target_panel: Control = board_container.get_child(1)
	var dead_button: Button = target_panel.get_node("DeadButton")
	dead_button.pressed.emit()

	var revived_target_panel: Control = board_container.get_child(1)
	var top_hit_button: Button = revived_target_panel.get_node("HitZones/TopHitButton")
	assert_false(top_hit_button.disabled)

	var row: HBoxContainer = revived_target_panel.get_node("CommanderDamageContainer/CommanderDamageList/Source_0")
	var minus_button: Button = row.get_node("MinusButton")
	_tap_commander_button(minus_button)

	var next_players: Array = tracker.game_state.get("players", [])
	var next_target_player: Dictionary = next_players[1]
	var next_damage_map: Dictionary = next_target_player.get("commander_damage", {})
	assert_eq(int(next_damage_map.get("p1", 0)), 20)

func test_commander_damage_value_is_preserved_through_dead_and_revive() -> void:
	var state: Dictionary = GAME_STATE_SCRIPT.create_new_game(2, 40, "p2_head_to_head")
	var players: Array = state.get("players", [])
	var target_player: Dictionary = players[1]
	var damage_map: Dictionary = target_player.get("commander_damage", {})
	damage_map["p1"] = 6
	target_player["commander_damage"] = damage_map
	players[1] = target_player
	state["players"] = players

	var tracker: Control = _create_tracker(state)
	var board_container: Control = tracker.get_node("VBoxContainer/BoardContainer")
	var source_panel: Control = board_container.get_child(0)
	var dead_button: Button = source_panel.get_node("DeadButton")
	dead_button.pressed.emit()

	var source_panel_after_death: Control = board_container.get_child(0)
	var dead_button_after_death: Button = source_panel_after_death.get_node("DeadButton")
	dead_button_after_death.pressed.emit()

	var revived_target_panel: Control = board_container.get_child(1)
	var row: HBoxContainer = revived_target_panel.get_node("CommanderDamageContainer/CommanderDamageList/Source_0")
	var damage_label: Label = row.get_node("DamageLabel")
	assert_eq(damage_label.text, "6")

func test_manual_dead_state_is_persisted_after_reload() -> void:
	var state: Dictionary = GAME_STATE_SCRIPT.create_new_game(2, 40, "p2_head_to_head")
	var context: Dictionary = _create_tracker_and_store(state)
	var tracker: Control = context["tracker"]
	var fake_store: FakeStore = context["store"]
	var board_container: Control = tracker.get_node("VBoxContainer/BoardContainer")
	var source_panel: Control = board_container.get_child(0)
	var dead_button: Button = source_panel.get_node("DeadButton")
	dead_button.pressed.emit()

	var reloaded_tracker: Control = _create_tracker_from_store(fake_store)
	var reloaded_board: Control = reloaded_tracker.get_node("VBoxContainer/BoardContainer")
	var reloaded_source_panel: Control = reloaded_board.get_child(0)
	var top_hit_button: Button = reloaded_source_panel.get_node("HitZones/TopHitButton")
	assert_true(top_hit_button.disabled)

func test_revived_at_lethal_state_is_persisted_after_reload() -> void:
	var state: Dictionary = GAME_STATE_SCRIPT.create_new_game(2, 40, "p2_head_to_head")
	var players: Array = state.get("players", [])
	var target_player: Dictionary = players[1]
	var damage_map: Dictionary = target_player.get("commander_damage", {})
	damage_map["p1"] = 21
	target_player["commander_damage"] = damage_map
	players[1] = target_player
	state["players"] = players
	var context: Dictionary = _create_tracker_and_store(state)
	var tracker: Control = context["tracker"]
	var fake_store: FakeStore = context["store"]
	var board_container: Control = tracker.get_node("VBoxContainer/BoardContainer")
	var target_panel: Control = board_container.get_child(1)
	var dead_button: Button = target_panel.get_node("DeadButton")
	dead_button.pressed.emit()

	var reloaded_tracker: Control = _create_tracker_from_store(fake_store)
	var reloaded_board: Control = reloaded_tracker.get_node("VBoxContainer/BoardContainer")
	var reloaded_target_panel: Control = reloaded_board.get_child(1)
	var top_hit_button: Button = reloaded_target_panel.get_node("HitZones/TopHitButton")
	assert_false(top_hit_button.disabled)

func test_commander_minus_does_not_set_negative_damage_in_state() -> void:
	var state: Dictionary = GAME_STATE_SCRIPT.create_new_game(2, 40, "p2_head_to_head")
	var tracker: Control = _create_tracker(state)
	var board_container: Control = tracker.get_node("VBoxContainer/BoardContainer")
	var target_panel: Control = board_container.get_child(1)
	var row: HBoxContainer = target_panel.get_node("CommanderDamageContainer/CommanderDamageList/Source_0")
	var minus_button: Button = row.get_node("MinusButton")
	_tap_commander_button(minus_button)

	var players: Array = tracker.game_state.get("players", [])
	var target_player: Dictionary = players[1]
	var damage_map: Dictionary = target_player.get("commander_damage", {})
	assert_eq(int(damage_map.get("p1", -1)), 0)

func test_commander_minus_keeps_life_unchanged_when_damage_is_zero() -> void:
	var state: Dictionary = GAME_STATE_SCRIPT.create_new_game(2, 40, "p2_head_to_head")
	var tracker: Control = _create_tracker(state)
	var board_container: Control = tracker.get_node("VBoxContainer/BoardContainer")
	var target_panel: Control = board_container.get_child(1)
	var row: HBoxContainer = target_panel.get_node("CommanderDamageContainer/CommanderDamageList/Source_0")
	var minus_button: Button = row.get_node("MinusButton")
	_tap_commander_button(minus_button)

	var players: Array = tracker.game_state.get("players", [])
	var target_player: Dictionary = players[1]
	assert_eq(int(target_player.get("life", 0)), 40)

func test_commander_minus_at_zero_updates_damage_label_to_zero() -> void:
	var state: Dictionary = GAME_STATE_SCRIPT.create_new_game(2, 40, "p2_head_to_head")
	var tracker: Control = _create_tracker(state)
	var board_container: Control = tracker.get_node("VBoxContainer/BoardContainer")
	var target_panel: Control = board_container.get_child(1)
	var row: HBoxContainer = target_panel.get_node("CommanderDamageContainer/CommanderDamageList/Source_0")
	var minus_button: Button = row.get_node("MinusButton")
	_tap_commander_button(minus_button)

	var damage_label: Label = row.get_node("DamageLabel")
	assert_eq(damage_label.text, "0")

func test_removing_commander_damage_reduces_damage_by_one() -> void:
	var state: Dictionary = GAME_STATE_SCRIPT.create_new_game(2, 40, "p2_head_to_head")
	var tracker: Control = _create_tracker(state)
	var board_container: Control = tracker.get_node("VBoxContainer/BoardContainer")
	var target_panel: Control = board_container.get_child(1)
	var row: HBoxContainer = target_panel.get_node("CommanderDamageContainer/CommanderDamageList/Source_0")
	var plus_button: Button = row.get_node("PlusButton")
	var minus_button: Button = row.get_node("MinusButton")

	_tap_commander_button(plus_button)
	_tap_commander_button(plus_button)
	_tap_commander_button(minus_button)

	var players: Array = tracker.game_state.get("players", [])
	var target_player: Dictionary = players[1]
	var damage_map: Dictionary = target_player.get("commander_damage", {})
	assert_eq(int(damage_map.get("p1", 0)), 1)

func test_removing_commander_damage_restores_life_by_one() -> void:
	var state: Dictionary = GAME_STATE_SCRIPT.create_new_game(2, 40, "p2_head_to_head")
	var tracker: Control = _create_tracker(state)
	var board_container: Control = tracker.get_node("VBoxContainer/BoardContainer")
	var target_panel: Control = board_container.get_child(1)
	var row: HBoxContainer = target_panel.get_node("CommanderDamageContainer/CommanderDamageList/Source_0")
	var plus_button: Button = row.get_node("PlusButton")
	var minus_button: Button = row.get_node("MinusButton")

	_tap_commander_button(plus_button)
	_tap_commander_button(plus_button)
	_tap_commander_button(minus_button)

	var players: Array = tracker.game_state.get("players", [])
	var target_player: Dictionary = players[1]
	assert_eq(int(target_player.get("life", 0)), 39)

func test_removing_commander_damage_updates_damage_label() -> void:
	var state: Dictionary = GAME_STATE_SCRIPT.create_new_game(2, 40, "p2_head_to_head")
	var tracker: Control = _create_tracker(state)
	var board_container: Control = tracker.get_node("VBoxContainer/BoardContainer")
	var target_panel: Control = board_container.get_child(1)
	var row: HBoxContainer = target_panel.get_node("CommanderDamageContainer/CommanderDamageList/Source_0")
	var plus_button: Button = row.get_node("PlusButton")
	var minus_button: Button = row.get_node("MinusButton")

	_tap_commander_button(plus_button)
	_tap_commander_button(plus_button)
	_tap_commander_button(minus_button)

	var damage_label: Label = row.get_node("DamageLabel")
	assert_eq(damage_label.text, "1")

func test_removing_commander_damage_updates_life_label() -> void:
	var state: Dictionary = GAME_STATE_SCRIPT.create_new_game(2, 40, "p2_head_to_head")
	var tracker: Control = _create_tracker(state)
	var board_container: Control = tracker.get_node("VBoxContainer/BoardContainer")
	var target_panel: Control = board_container.get_child(1)
	var row: HBoxContainer = target_panel.get_node("CommanderDamageContainer/CommanderDamageList/Source_0")
	var plus_button: Button = row.get_node("PlusButton")
	var minus_button: Button = row.get_node("MinusButton")

	_tap_commander_button(plus_button)
	_tap_commander_button(plus_button)
	_tap_commander_button(minus_button)

	var life_label: Label = target_panel.get_node("MiddleArea/LifeLabel")
	assert_eq(life_label.text, "39")

func test_menu_starts_closed() -> void:
	var state: Dictionary = GAME_STATE_SCRIPT.create_new_game(2, 40, "p2_head_to_head")
	var tracker: Control = _create_tracker(state)
	var menu_panel: Control = tracker.get_node("TrackerMenuOverlay/MenuPanel")
	assert_false(menu_panel.visible)

func test_menu_button_is_visible_on_start() -> void:
	var state: Dictionary = GAME_STATE_SCRIPT.create_new_game(2, 40, "p2_head_to_head")
	var tracker: Control = _create_tracker(state)
	var menu_button: Button = tracker.get_node("TrackerMenuOverlay/MenuButton")
	assert_true(menu_button.visible)

func test_menu_input_blocker_ignores_input_on_start() -> void:
	var state: Dictionary = GAME_STATE_SCRIPT.create_new_game(2, 40, "p2_head_to_head")
	var tracker: Control = _create_tracker(state)
	var input_blocker: Control = tracker.get_node("TrackerMenuOverlay/InputBlocker")
	assert_eq(input_blocker.mouse_filter, Control.MOUSE_FILTER_IGNORE)

func test_menu_button_opens_menu_panel() -> void:
	var state: Dictionary = GAME_STATE_SCRIPT.create_new_game(2, 40, "p2_head_to_head")
	var tracker: Control = _create_tracker(state)
	var menu_panel: Control = tracker.get_node("TrackerMenuOverlay/MenuPanel")
	var menu_button: Button = tracker.get_node("TrackerMenuOverlay/MenuButton")
	menu_button.pressed.emit()
	assert_true(menu_panel.visible)

func test_menu_button_sets_input_blocker_to_stop_when_opened() -> void:
	var state: Dictionary = GAME_STATE_SCRIPT.create_new_game(2, 40, "p2_head_to_head")
	var tracker: Control = _create_tracker(state)
	var input_blocker: Control = tracker.get_node("TrackerMenuOverlay/InputBlocker")
	var menu_button: Button = tracker.get_node("TrackerMenuOverlay/MenuButton")
	menu_button.pressed.emit()
	assert_eq(input_blocker.mouse_filter, Control.MOUSE_FILTER_STOP)

func test_menu_button_closes_menu_panel_when_pressed_twice() -> void:
	var state: Dictionary = GAME_STATE_SCRIPT.create_new_game(2, 40, "p2_head_to_head")
	var tracker: Control = _create_tracker(state)
	var menu_panel: Control = tracker.get_node("TrackerMenuOverlay/MenuPanel")
	var menu_button: Button = tracker.get_node("TrackerMenuOverlay/MenuButton")
	menu_button.pressed.emit()
	menu_button.pressed.emit()
	assert_false(menu_panel.visible)

func test_menu_button_sets_input_blocker_to_ignore_when_closed() -> void:
	var state: Dictionary = GAME_STATE_SCRIPT.create_new_game(2, 40, "p2_head_to_head")
	var tracker: Control = _create_tracker(state)
	var input_blocker: Control = tracker.get_node("TrackerMenuOverlay/InputBlocker")
	var menu_button: Button = tracker.get_node("TrackerMenuOverlay/MenuButton")
	menu_button.pressed.emit()
	menu_button.pressed.emit()
	assert_eq(input_blocker.mouse_filter, Control.MOUSE_FILTER_IGNORE)

func test_roll_starter_action_opens_starter_roll_overlay() -> void:
	var state: Dictionary = GAME_STATE_SCRIPT.create_new_game(2, 40, "p2_head_to_head")
	var tracker: Control = _create_tracker(state)
	_open_starter_roll_from_menu(tracker)

	var starter_roll_overlay: Control = tracker.get_node("StarterRollOverlay")
	assert_true(starter_roll_overlay.visible)

func test_roll_starter_excludes_dead_players_from_candidates() -> void:
	var state: Dictionary = GAME_STATE_SCRIPT.create_new_game(2, 40, "p2_head_to_head")
	var tracker: Control = _create_tracker(state)
	var board_container: Control = tracker.get_node("VBoxContainer/BoardContainer")
	var source_panel: Control = board_container.get_child(0)
	var dead_button: Button = source_panel.get_node("DeadButton")
	dead_button.pressed.emit()

	_open_starter_roll_from_menu(tracker)
	var starter_roll_overlay: Control = tracker.get_node("StarterRollOverlay")
	assert_eq(int(starter_roll_overlay.call("get_current_candidate_count")), 1)

func test_starting_roll_winner_gets_crown_in_name_label() -> void:
	var state: Dictionary = GAME_STATE_SCRIPT.create_new_game(2, 40, "p2_head_to_head")
	var tracker: Control = _create_tracker(state)
	var starter_roll_overlay: Control = tracker.get_node("StarterRollOverlay")
	var forced_values: Array[int] = [2, 6]
	starter_roll_overlay.call("set_forced_roll_values", forced_values)
	var roll_players: Array[Dictionary] = tracker.call("_build_starter_roll_players")
	starter_roll_overlay.call("start_roll_for_players", roll_players, false)

	var board_container: Control = tracker.get_node("VBoxContainer/BoardContainer")
	var winner_panel: Control = board_container.get_child(1)
	var name_label: Label = winner_panel.get_node("HeaderArea/NameLabel")
	assert_true(name_label.text.ends_with(" \u2655"))

func test_starting_roll_winner_is_persisted_after_reload() -> void:
	var state: Dictionary = GAME_STATE_SCRIPT.create_new_game(2, 40, "p2_head_to_head")
	var context: Dictionary = _create_tracker_and_store(state)
	var tracker: Control = context["tracker"]
	var fake_store: FakeStore = context["store"]
	var starter_roll_overlay: Control = tracker.get_node("StarterRollOverlay")
	var forced_values: Array[int] = [2, 6]
	starter_roll_overlay.call("set_forced_roll_values", forced_values)
	var roll_players: Array[Dictionary] = tracker.call("_build_starter_roll_players")
	starter_roll_overlay.call("start_roll_for_players", roll_players, false)

	var reloaded_tracker: Control = _create_tracker_from_store(fake_store)
	var board_container: Control = reloaded_tracker.get_node("VBoxContainer/BoardContainer")
	var winner_panel: Control = board_container.get_child(1)
	var name_label: Label = winner_panel.get_node("HeaderArea/NameLabel")
	assert_true(name_label.text.ends_with(" \u2655"))

