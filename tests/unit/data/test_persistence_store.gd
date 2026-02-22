extends GutTest

const PERSISTENCE_STORE_SCRIPT: GDScript = preload("res://scripts/data/persistence_store.gd")
const GAME_STATE_SCRIPT: GDScript = preload("res://scripts/domain/game_state.gd")

var store: RefCounted

func before_each() -> void:
	store = PERSISTENCE_STORE_SCRIPT.new()
	store.clear_active_game()

func after_each() -> void:
	store.clear_active_game()

func test_has_active_game_false_when_cleared() -> void:
	assert_false(store.has_active_game())

func test_save_active_game_returns_true_for_valid_state() -> void:
	var state: Dictionary = GAME_STATE_SCRIPT.create_new_game(3, 40, "p3_side_left")
	assert_true(store.save_active_game(state))

func test_load_active_game_returns_valid_state_after_save() -> void:
	var state: Dictionary = GAME_STATE_SCRIPT.create_new_game(3, 40, "p3_side_left")
	store.save_active_game(state)
	var loaded: Dictionary = store.load_active_game()
	assert_true(GAME_STATE_SCRIPT.validate(loaded))

func test_load_active_game_preserves_player_count() -> void:
	var state: Dictionary = GAME_STATE_SCRIPT.create_new_game(3, 40, "p3_side_left")
	store.save_active_game(state)
	var loaded: Dictionary = store.load_active_game()
	assert_eq(loaded["settings"]["player_count"], 3)

func test_load_active_game_preserves_starting_life_value() -> void:
	var state: Dictionary = GAME_STATE_SCRIPT.create_new_game(3, 40, "p3_side_left")
	store.save_active_game(state)
	var loaded: Dictionary = store.load_active_game()
	assert_eq(loaded["settings"]["starting_life"], 40)

func test_load_active_game_preserves_starting_life_type_as_int() -> void:
	var state: Dictionary = GAME_STATE_SCRIPT.create_new_game(3, 40, "p3_side_left")
	store.save_active_game(state)
	var loaded: Dictionary = store.load_active_game()
	assert_eq(typeof(loaded["settings"]["starting_life"]), TYPE_INT)

func test_load_active_game_preserves_player_life_type_as_int() -> void:
	var state: Dictionary = GAME_STATE_SCRIPT.create_new_game(3, 40, "p3_side_left")
	store.save_active_game(state)
	var loaded: Dictionary = store.load_active_game()

	var players: Array = loaded.get("players", [])
	var first_player: Dictionary = players[0]
	assert_eq(typeof(first_player.get("life", null)), TYPE_INT)

func test_load_uses_backup_when_active_missing() -> void:
	var first_state: Dictionary = GAME_STATE_SCRIPT.create_new_game(4, 40, "p4_two_facing_two")
	assert_true(store.save_active_game(first_state))

	var second_state: Dictionary = GAME_STATE_SCRIPT.create_new_game(4, 35, "p4_side_seats")
	assert_true(store.save_active_game(second_state))

	var active_abs: String = ProjectSettings.globalize_path(PERSISTENCE_STORE_SCRIPT.ACTIVE_SAVE_PATH)
	DirAccess.remove_absolute(active_abs)

	var loaded: Dictionary = store.load_active_game()
	assert_true(GAME_STATE_SCRIPT.validate(loaded))
	assert_eq(loaded["settings"]["starting_life"], 40)

func test_backup_restore_keeps_starting_life_type_as_int() -> void:
	var first_state: Dictionary = GAME_STATE_SCRIPT.create_new_game(4, 40, "p4_two_facing_two")
	store.save_active_game(first_state)
	store.save_active_game(GAME_STATE_SCRIPT.create_new_game(4, 35, "p4_side_seats"))

	var active_abs: String = ProjectSettings.globalize_path(PERSISTENCE_STORE_SCRIPT.ACTIVE_SAVE_PATH)
	DirAccess.remove_absolute(active_abs)
	var loaded: Dictionary = store.load_active_game()
	assert_eq(typeof(loaded["settings"]["starting_life"]), TYPE_INT)
