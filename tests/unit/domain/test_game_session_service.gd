extends GutTest

const GAME_STATE_SCRIPT: GDScript = preload("res://scripts/domain/game_state.gd")

class FakeStore extends "res://scripts/contracts/game_store.gd":
	var has_game: bool = false
	var load_state: Dictionary = {}
	var save_calls: int = 0

	func has_active_game() -> bool:
		return has_game

	func load_active_game() -> Dictionary:
		return load_state.duplicate(true)

	func save_active_game(state: Dictionary) -> bool:
		save_calls += 1
		load_state = state.duplicate(true)
		return true

func test_apply_life_delta_updates_int_life() -> void:
	var state: Dictionary = GAME_STATE_SCRIPT.create_new_game(2, 40, "p2_head_to_head")
	var service_script: GDScript = load("res://scripts/domain/game_session_service.gd")
	var service: Object = service_script.new()

	var changed: bool = service.apply_life_delta(state, 0, -3)
	assert_true(changed)

	var players: Array = state.get("players", [])
	var player0: Dictionary = players[0]
	assert_eq(player0.get("life", 0), 37)
	assert_eq(typeof(player0.get("life", null)), TYPE_INT)

func test_apply_commander_delta_never_goes_below_zero() -> void:
	var state: Dictionary = GAME_STATE_SCRIPT.create_new_game(2, 40, "p2_head_to_head")
	var service_script: GDScript = load("res://scripts/domain/game_session_service.gd")
	var service: Object = service_script.new()

	assert_true(service.apply_commander_delta(state, 0, 1, 2))
	assert_true(service.apply_commander_delta(state, 0, 1, -5))

	var players: Array = state.get("players", [])
	var target: Dictionary = players[1]
	var damage: Dictionary = target.get("commander_damage", {})
	assert_eq(damage.get("p1", -1), 0)

func test_save_state_delegates_to_store() -> void:
	var fake_store: FakeStore = FakeStore.new()
	var service_script: GDScript = load("res://scripts/domain/game_session_service.gd")
	var service: Object = service_script.new(fake_store)
	var state: Dictionary = GAME_STATE_SCRIPT.create_new_game(2, 40, "p2_head_to_head")

	assert_true(service.save_state(state))
	assert_eq(fake_store.save_calls, 1)

