extends RefCounted

static func get_player_life(state: Dictionary, player_index: int) -> int:
	var player: Dictionary = _get_player(state, player_index)
	if player.is_empty():
		return 0
	return int(player.get("life", 0))

static func get_commander_damage(state: Dictionary, source_index: int, target_index: int) -> int:
	var source: Dictionary = _get_player(state, source_index)
	var target: Dictionary = _get_player(state, target_index)
	if source.is_empty() or target.is_empty():
		return 0

	var source_id: String = str(source.get("id", ""))
	var damage_value: Variant = target.get("commander_damage", {})
	if typeof(damage_value) != TYPE_DICTIONARY:
		return 0

	var damage_map: Dictionary = damage_value
	return int(damage_map.get(source_id, 0))

static func build_commander_rows_for_target(state: Dictionary, target_player_index: int, player_colors: Array[Color]) -> Array[Dictionary]:
	var players: Array = _get_players(state)
	var rows: Array[Dictionary] = []
	if target_player_index < 0 or target_player_index >= players.size():
		return rows

	var target_value: Variant = players[target_player_index]
	if typeof(target_value) != TYPE_DICTIONARY:
		return rows

	var target: Dictionary = target_value
	var damage_value: Variant = target.get("commander_damage", {})
	var damage_map: Dictionary = damage_value if typeof(damage_value) == TYPE_DICTIONARY else {}

	for source_player_index: int in range(players.size()):
		if source_player_index == target_player_index:
			continue

		var source_value: Variant = players[source_player_index]
		if typeof(source_value) != TYPE_DICTIONARY:
			continue
		var source: Dictionary = source_value
		var source_id: String = str(source.get("id", ""))
		rows.append({
			"source_index": source_player_index,
			"source_name": str(source.get("name", "Player")),
			"damage": int(damage_map.get(source_id, 0)),
			"source_color": player_colors[source_player_index % player_colors.size()]
		})

	return rows

static func _get_players(state: Dictionary) -> Array:
	var players_value: Variant = state.get("players", [])
	if typeof(players_value) != TYPE_ARRAY:
		return []
	return players_value

static func _get_player(state: Dictionary, player_index: int) -> Dictionary:
	var players: Array = _get_players(state)
	if player_index < 0 or player_index >= players.size():
		return {}

	var player_value: Variant = players[player_index]
	if typeof(player_value) != TYPE_DICTIONARY:
		return {}
	return player_value
