extends GutTest

class FakeSession extends "res://scripts/contracts/game_session.gd":
	var state: Dictionary = {}
	var save_calls: int = 0

	func _init(p_state: Dictionary = {}) -> void:
		state = p_state.duplicate(true)

	func load_active_game() -> Dictionary:
		return state.duplicate(true)

	func save_state(next_state: Dictionary) -> bool:
		save_calls += 1
		state = next_state.duplicate(true)
		return true

	func apply_life_delta(next_state: Dictionary, player_index: int, delta: int) -> bool:
		var players: Array = next_state.get("players", [])
		if player_index < 0 or player_index >= players.size():
			return false
		var player: Dictionary = players[player_index]
		player["life"] = int(player.get("life", 0)) + delta
		players[player_index] = player
		next_state["players"] = players
		return true

func test_apply_life_delta_commits_through_session() -> void:
	var initial_state: Dictionary = GameState.create_new_game(2, 40, "p2_head_to_head")
	var session: FakeSession = FakeSession.new(initial_state)
	var controller: RefCounted = LifeTrackerController.new(session)

	controller.load_state()
	assert_true(controller.apply_life_delta(0, 2))
	assert_eq(session.save_calls, 1)

	var players: Array = controller.get_state().get("players", [])
	var player: Dictionary = players[0]
	assert_eq(player.get("life", 0), 42)

func test_commit_state_returns_false_when_empty() -> void:
	var session: FakeSession = FakeSession.new({})
	var controller: RefCounted = LifeTrackerController.new(session)
	assert_false(controller.commit_state())
