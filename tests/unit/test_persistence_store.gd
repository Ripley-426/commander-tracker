extends GutTest

var store: PersistenceStore

func before_each() -> void:
	store = PersistenceStore.new()
	store.clear_active_game()

func after_each() -> void:
	store.clear_active_game()

func test_has_active_game_false_when_cleared() -> void:
	assert_false(store.has_active_game())

func test_save_and_load_active_game_round_trip() -> void:
	var state: Dictionary = GameState.create_new_game(3, 40, "p3_side_left")
	var save_ok: bool = store.save_active_game(state)
	assert_true(save_ok)

	var loaded: Dictionary = store.load_active_game()
	assert_true(GameState.validate(loaded))
	assert_eq(loaded["settings"]["player_count"], 3)
	assert_eq(loaded["settings"]["starting_life"], 40)
	assert_eq(typeof(loaded["settings"]["starting_life"]), TYPE_INT)

	var players: Array = loaded.get("players", [])
	var first_player: Dictionary = players[0]
	assert_eq(typeof(first_player.get("life", null)), TYPE_INT)

func test_load_uses_backup_when_active_missing() -> void:
	var first_state: Dictionary = GameState.create_new_game(4, 40, "p4_two_facing_two")
	assert_true(store.save_active_game(first_state))

	var second_state: Dictionary = GameState.create_new_game(4, 35, "p4_side_seats")
	assert_true(store.save_active_game(second_state))

	var active_abs: String = ProjectSettings.globalize_path(PersistenceStore.ACTIVE_SAVE_PATH)
	DirAccess.remove_absolute(active_abs)

	var loaded: Dictionary = store.load_active_game()
	assert_true(GameState.validate(loaded))
	assert_eq(loaded["settings"]["starting_life"], 40)
	assert_eq(typeof(loaded["settings"]["starting_life"]), TYPE_INT)
