extends RefCounted
class_name LifeTrackerController

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
	var players_value: Variant = game_state.get("players", [])
	if typeof(players_value) != TYPE_ARRAY:
		return 0
	var players: Array = players_value
	if source_index < 0 or source_index >= players.size():
		return 0
	if target_index < 0 or target_index >= players.size():
		return 0

	var source_value: Variant = players[source_index]
	var target_value: Variant = players[target_index]
	if typeof(source_value) != TYPE_DICTIONARY or typeof(target_value) != TYPE_DICTIONARY:
		return 0

	var source: Dictionary = source_value
	var target: Dictionary = target_value
	var source_id: String = str(source.get("id", ""))
	var damage_value: Variant = target.get("commander_damage", {})
	if typeof(damage_value) != TYPE_DICTIONARY:
		return 0
	var damage_map: Dictionary = damage_value
	return int(damage_map.get(source_id, 0))

func commit_state() -> bool:
	if game_state.is_empty():
		return false
	return session.save_state(game_state)
