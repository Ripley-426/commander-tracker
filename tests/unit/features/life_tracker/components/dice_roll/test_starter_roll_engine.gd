extends GutTest

func _create_engine() -> RefCounted:
	var script: GDScript = load("res://scripts/features/life_tracker/components/dice_roll/starter_roll_engine.gd")
	return script.new()

func _build_players() -> Array[Dictionary]:
	return [
		{"player_index": 0, "player_name": "Player 1"},
		{"player_index": 1, "player_name": "Player 2"},
		{"player_index": 2, "player_name": "Player 3"}
	]

func test_roll_round_uses_forced_values_in_order() -> void:
	var engine: RefCounted = _create_engine()
	var forced_values: Array[int] = [2, 5, 4]
	engine.call("set_forced_roll_values", forced_values)
	var outcome: Dictionary = engine.call("roll_round", _build_players())
	var round_results: Dictionary = outcome.get("round_results", {})
	assert_eq(int(round_results.get("0", 0)), 2)

func test_roll_round_sets_highest_roll() -> void:
	var engine: RefCounted = _create_engine()
	var forced_values: Array[int] = [2, 5, 4]
	engine.call("set_forced_roll_values", forced_values)
	var outcome: Dictionary = engine.call("roll_round", _build_players())
	assert_eq(int(outcome.get("highest_roll", 0)), 5)

func test_roll_round_returns_tied_players_for_highest_roll() -> void:
	var engine: RefCounted = _create_engine()
	var forced_values: Array[int] = [6, 6, 2]
	engine.call("set_forced_roll_values", forced_values)
	var outcome: Dictionary = engine.call("roll_round", _build_players())
	var tied_players: Array = outcome.get("tied_players", [])
	assert_eq(tied_players.size(), 2)

func test_roll_round_sets_winner_player_index_when_single_winner() -> void:
	var engine: RefCounted = _create_engine()
	var forced_values: Array[int] = [1, 3, 2]
	engine.call("set_forced_roll_values", forced_values)
	var outcome: Dictionary = engine.call("roll_round", _build_players())
	assert_eq(int(outcome.get("winner_player_index", -1)), 1)

func test_roll_round_has_no_winner_when_tied() -> void:
	var engine: RefCounted = _create_engine()
	var forced_values: Array[int] = [4, 4, 1]
	engine.call("set_forced_roll_values", forced_values)
	var outcome: Dictionary = engine.call("roll_round", _build_players())
	assert_eq(int(outcome.get("winner_player_index", -1)), -1)
