extends RefCounted

const PLAYER_STATE_QUERIES: GDScript = preload("res://scripts/domain/player_state_queries.gd")

var session: RefCounted
var game_state: Dictionary = {}

func _init(p_session: RefCounted) -> void:
	session = p_session

func load_state() -> Dictionary:
	game_state = session.load_active_game()
	return game_state

func get_state() -> Dictionary:
	return game_state

func apply_life_delta(player_index: int, delta: int) -> bool:
	var changed: bool = session.apply_life_delta(game_state, player_index, delta)
	if changed:
		commit_state()
	return changed

func apply_commander_delta(source_index: int, target_index: int, delta: int) -> bool:
	var changed: bool = session.apply_commander_delta(game_state, source_index, target_index, delta)
	if changed:
		commit_state()
	return changed

func apply_commander_delta_with_life_loss(source_index: int, target_index: int, delta: int) -> bool:
	var previous_damage: int = _get_commander_damage(source_index, target_index)
	var changed: bool = session.apply_commander_delta(game_state, source_index, target_index, delta)
	if not changed:
		return false

	var next_damage: int = _get_commander_damage(source_index, target_index)
	var applied_damage_delta: int = next_damage - previous_damage
	if applied_damage_delta != 0:
		session.apply_life_delta(game_state, target_index, -applied_damage_delta)

	commit_state()
	return true

func _get_commander_damage(source_index: int, target_index: int) -> int:
	return PLAYER_STATE_QUERIES.get_commander_damage(game_state, source_index, target_index)

func commit_state() -> bool:
	if game_state.is_empty():
		return false
	return session.save_state(game_state)
