extends GutTest

const GAME_STATE_SCRIPT: GDScript = preload("res://scripts/domain/game_state.gd")

func test_get_layout_presets_exist_for_supported_player_counts() -> void:
	for player_count: int in range(2, 7):
		var presets: Array[Dictionary] = GAME_STATE_SCRIPT.get_layout_presets(player_count)
		assert_true(presets.size() > 0, "Expected presets for player count %d" % player_count)

func test_create_new_game_returns_valid_state() -> void:
	var state: Dictionary = GAME_STATE_SCRIPT.create_new_game(4, 40, "p4_two_facing_two")
	assert_true(GAME_STATE_SCRIPT.validate(state))

func test_create_new_game_sets_version_to_one() -> void:
	var state: Dictionary = GAME_STATE_SCRIPT.create_new_game(4, 40, "p4_two_facing_two")
	assert_eq(state["version"], 1)

func test_create_new_game_creates_expected_player_count() -> void:
	var state: Dictionary = GAME_STATE_SCRIPT.create_new_game(4, 40, "p4_two_facing_two")
	var players: Array[Dictionary] = state["players"]
	assert_eq(players.size(), 4)

func test_create_new_game_sets_each_player_life_to_starting_life() -> void:
	var state: Dictionary = GAME_STATE_SCRIPT.create_new_game(4, 40, "p4_two_facing_two")
	var players: Array[Dictionary] = state["players"]
	for player: Dictionary in players:
		assert_eq(player["life"], 40)

func test_create_new_game_initializes_commander_damage_entries_for_other_players() -> void:
	var state: Dictionary = GAME_STATE_SCRIPT.create_new_game(4, 40, "p4_two_facing_two")
	var players: Array[Dictionary] = state["players"]
	for player: Dictionary in players:
		var commander_damage: Dictionary = player["commander_damage"]
		assert_eq(commander_damage.size(), 3)

func test_create_new_game_initializes_runtime_dead_state_maps() -> void:
	var state: Dictionary = GAME_STATE_SCRIPT.create_new_game(4, 40, "p4_two_facing_two")
	assert_eq(typeof(state.get("dead_player_indices", null)), TYPE_DICTIONARY)
	assert_eq(typeof(state.get("revived_at_lethal_damage_indices", null)), TYPE_DICTIONARY)

func test_validate_rejects_invalid_state() -> void:
	var invalid_state: Dictionary = {
		"version": 1,
		"settings": {"player_count": 1, "starting_life": 40, "layout_id": "bad"},
		"players": []
	}
	assert_false(GAME_STATE_SCRIPT.validate(invalid_state))

func test_normalize_loaded_state_converts_starting_player_index_to_int() -> void:
	var state: Dictionary = GAME_STATE_SCRIPT.create_new_game(2, 40, "p2_head_to_head")
	state["starting_player_index"] = 1.0
	var normalized: Dictionary = GAME_STATE_SCRIPT.normalize_loaded_state(state)
	assert_eq(typeof(normalized.get("starting_player_index", null)), TYPE_INT)

func test_normalize_loaded_state_converts_runtime_dead_state_maps() -> void:
	var state: Dictionary = GAME_STATE_SCRIPT.create_new_game(2, 40, "p2_head_to_head")
	state["dead_player_indices"] = {"1": true, "bad": true}
	state["revived_at_lethal_damage_indices"] = {"1": true, "-1": true}
	var normalized: Dictionary = GAME_STATE_SCRIPT.normalize_loaded_state(state)
	var dead_map: Dictionary = normalized.get("dead_player_indices", {})
	var revived_map: Dictionary = normalized.get("revived_at_lethal_damage_indices", {})
	assert_true(dead_map.has("1"))
	assert_false(dead_map.has("bad"))
	assert_true(revived_map.has("1"))
	assert_false(revived_map.has("-1"))
