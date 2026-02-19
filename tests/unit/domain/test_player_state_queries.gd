extends GutTest

const PLAYER_STATE_QUERIES: GDScript = preload("res://scripts/domain/player_state_queries.gd")
const GAME_STATE_SCRIPT: GDScript = preload("res://scripts/domain/game_state.gd")

func test_get_player_life_returns_value_and_handles_invalid_index() -> void:
	var state: Dictionary = GAME_STATE_SCRIPT.create_new_game(2, 40, "p2_head_to_head")
	assert_eq(PLAYER_STATE_QUERIES.get_player_life(state, 0), 40)
	assert_eq(PLAYER_STATE_QUERIES.get_player_life(state, 7), 0)

func test_get_commander_damage_reads_target_map_for_source() -> void:
	var state: Dictionary = GAME_STATE_SCRIPT.create_new_game(2, 40, "p2_head_to_head")
	var players: Array = state.get("players", [])
	var target: Dictionary = players[1]
	var damage_map: Dictionary = target.get("commander_damage", {})
	damage_map["p1"] = 6
	target["commander_damage"] = damage_map
	players[1] = target
	state["players"] = players

	assert_eq(PLAYER_STATE_QUERIES.get_commander_damage(state, 0, 1), 6)
	assert_eq(PLAYER_STATE_QUERIES.get_commander_damage(state, 1, 0), 0)

func test_build_commander_rows_for_target_excludes_self_and_adds_color() -> void:
	var state: Dictionary = GAME_STATE_SCRIPT.create_new_game(3, 40, "p3_side_left")
	var colors: Array[Color] = [
		Color(1.0, 0.0, 0.0, 1.0),
		Color(0.0, 1.0, 0.0, 1.0),
		Color(0.0, 0.0, 1.0, 1.0)
	]

	var rows: Array[Dictionary] = PLAYER_STATE_QUERIES.build_commander_rows_for_target(state, 1, colors)
	assert_eq(rows.size(), 2)
	assert_eq(int(rows[0].get("source_index", -1)), 0)
	assert_eq(int(rows[1].get("source_index", -1)), 2)
	assert_eq(rows[0].get("source_color", Color()), colors[0])
	assert_eq(rows[1].get("source_color", Color()), colors[2])

