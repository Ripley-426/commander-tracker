extends "res://scripts/contracts/game_session.gd"

const PERSISTENCE_STORE_SCRIPT: GDScript = preload("res://scripts/data/persistence_store.gd")

var store: RefCounted

func _init(p_store: RefCounted = null) -> void:
	store = p_store if p_store != null else PERSISTENCE_STORE_SCRIPT.new()

func has_active_game() -> bool:
	return store.has_active_game()

func load_active_game() -> Dictionary:
	return store.load_active_game()

func save_state(state: Dictionary) -> bool:
	return store.save_active_game(state)

func describe_settings(state: Dictionary) -> String:
	var settings_value: Variant = state.get("settings", {})
	var settings: Dictionary = settings_value if typeof(settings_value) == TYPE_DICTIONARY else {}
	var count: int = int(settings.get("player_count", 0))
	var life: int = int(settings.get("starting_life", 0))
	var layout_id: String = str(settings.get("layout_id", ""))
	return "Players: %d | Starting Life: %d | Layout: %s" % [count, life, layout_id]

func apply_life_delta(state: Dictionary, player_index: int, delta: int) -> bool:
	var players_value: Variant = state.get("players", [])
	if typeof(players_value) != TYPE_ARRAY:
		return false
	var players: Array = players_value
	if player_index < 0 or player_index >= players.size():
		return false

	var player_value: Variant = players[player_index]
	if typeof(player_value) != TYPE_DICTIONARY:
		return false
	var player: Dictionary = player_value
	player["life"] = int(player.get("life", 0)) + delta
	players[player_index] = player
	state["players"] = players
	return true

func apply_commander_delta(state: Dictionary, source_index: int, target_index: int, delta: int) -> bool:
	var players_value: Variant = state.get("players", [])
	if typeof(players_value) != TYPE_ARRAY:
		return false
	var players: Array = players_value

	if source_index < 0 or source_index >= players.size():
		return false
	if target_index < 0 or target_index >= players.size() or target_index == source_index:
		return false

	var source_value: Variant = players[source_index]
	var target_value: Variant = players[target_index]
	if typeof(source_value) != TYPE_DICTIONARY or typeof(target_value) != TYPE_DICTIONARY:
		return false

	var source: Dictionary = source_value
	var target: Dictionary = target_value
	var source_id: String = str(source.get("id", ""))

	var damage_value: Variant = target.get("commander_damage", {})
	if typeof(damage_value) != TYPE_DICTIONARY:
		return false
	var damage: Dictionary = damage_value

	var next: int = int(damage.get(source_id, 0)) + delta
	damage[source_id] = max(next, 0)
	target["commander_damage"] = damage
	players[target_index] = target
	state["players"] = players
	return true
