extends GutTest

const GAME_STATE_SCRIPT: GDScript = preload("res://scripts/domain/game_state.gd")

func test_get_layout_presets_exist_for_supported_player_counts() -> void:
	for player_count: int in range(2, 7):
		var presets: Array[Dictionary] = GAME_STATE_SCRIPT.get_layout_presets(player_count)
		assert_true(presets.size() > 0, "Expected presets for player count %d" % player_count)

func test_create_new_game_creates_valid_state() -> void:
	var state: Dictionary = GAME_STATE_SCRIPT.create_new_game(4, 40, "p4_two_facing_two")
	assert_true(GAME_STATE_SCRIPT.validate(state))
	assert_eq(state["version"], 1)

	var players: Array[Dictionary] = state["players"]
	assert_eq(players.size(), 4)

	for player: Dictionary in players:
		assert_eq(player["life"], 40)
		var commander_damage: Dictionary = player["commander_damage"]
		assert_eq(commander_damage.size(), 3)

func test_validate_rejects_invalid_state() -> void:
	var invalid_state: Dictionary = {
		"version": 1,
		"settings": {"player_count": 1, "starting_life": 40, "layout_id": "bad"},
		"players": []
	}
	assert_false(GAME_STATE_SCRIPT.validate(invalid_state))

