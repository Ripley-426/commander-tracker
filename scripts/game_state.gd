extends RefCounted
class_name GameState

const VERSION := 1

static func _is_int_like(value: Variant) -> bool:
	if typeof(value) == TYPE_INT:
		return true
	if typeof(value) == TYPE_FLOAT:
		var number: float = value
		return is_equal_approx(number, round(number))
	return false

static func _to_int(value: Variant) -> int:
	if typeof(value) == TYPE_INT:
		return int(value)
	if typeof(value) == TYPE_FLOAT:
		return int(round(float(value)))
	return 0

static func get_layout_presets(player_count: int) -> Array[Dictionary]:
	match player_count:
		2:
			return [
				{"id": "p2_head_to_head", "name": "Head-to-Head"}
			]
		3:
			return [
				{"id": "p3_side_left", "name": "Two Opposed + Side Left"},
				{"id": "p3_side_right", "name": "Two Opposed + Side Right"}
			]
		4:
			return [
				{"id": "p4_two_facing_two", "name": "Two Facing Two"},
				{"id": "p4_side_seats", "name": "Opposed + Two Side Seats"}
			]
		5:
			return [
				{"id": "p5_side_bias_left", "name": "Opposed Core + Side Bias Left"},
				{"id": "p5_side_bias_right", "name": "Opposed Core + Side Bias Right"}
			]
		6:
			return [
				{"id": "p6_three_vs_three", "name": "Three Facing Three"},
				{"id": "p6_two_vs_two_sides", "name": "Two Facing Two + Side Seats"}
			]
		_:
			return []

static func create_new_game(player_count: int, starting_life: int, layout_id: String) -> Dictionary:
	var now := Time.get_unix_time_from_system()
	var players: Array[Dictionary] = []

	for i in range(player_count):
		players.append({
			"id": "p%d" % (i + 1),
			"name": "Player %d" % (i + 1),
			"life": starting_life,
			"commander_damage": {}
		})

	for target in players:
		var damage_map: Dictionary = target["commander_damage"]
		for source in players:
			if source["id"] == target["id"]:
				continue
			damage_map[source["id"]] = 0

	return {
		"version": VERSION,
		"in_progress": true,
		"created_at_unix": now,
		"updated_at_unix": now,
		"settings": {
			"player_count": player_count,
			"starting_life": starting_life,
			"layout_id": layout_id
		},
		"players": players
	}

static func validate(data: Dictionary) -> bool:
	if not _is_int_like(data.get("version", -1)):
		return false
	if int(data.get("version", -1)) != VERSION:
		return false
	if not data.has("settings") or not data.has("players"):
		return false

	var settings_value: Variant = data["settings"]
	var players_value: Variant = data["players"]
	if typeof(settings_value) != TYPE_DICTIONARY or typeof(players_value) != TYPE_ARRAY:
		return false

	var settings: Dictionary = settings_value
	var players: Array = players_value

	var raw_player_count: Variant = settings.get("player_count", -1)
	if not _is_int_like(raw_player_count):
		return false
	var player_count: int = int(raw_player_count)
	if player_count < 2 or player_count > 6:
		return false
	if players.size() != player_count:
		return false

	var ids: Array[String] = []
	for player_value: Variant in players:
		if typeof(player_value) != TYPE_DICTIONARY:
			return false
		var player: Dictionary = player_value
		var id: String = str(player.get("id", ""))
		if id.is_empty() or ids.has(id):
			return false
		ids.append(id)
		var life_value: Variant = player.get("life", null)
		if not _is_int_like(life_value):
			return false

	for player_value: Variant in players:
		var player: Dictionary = player_value
		var dmg_value: Variant = player.get("commander_damage", {})
		if typeof(dmg_value) != TYPE_DICTIONARY:
			return false
		var dmg: Dictionary = dmg_value
		for other_id in ids:
			if other_id == player["id"]:
				continue
			var damage_value: Variant = dmg.get(other_id, null)
			if not _is_int_like(damage_value):
				return false

	return true

static func normalize_loaded_state(data: Dictionary) -> Dictionary:
	var normalized: Dictionary = data.duplicate(true)
	normalized["version"] = _to_int(normalized.get("version", VERSION))

	var settings_value: Variant = normalized.get("settings", {})
	var settings: Dictionary = settings_value if typeof(settings_value) == TYPE_DICTIONARY else {}
	settings["player_count"] = _to_int(settings.get("player_count", 0))
	settings["starting_life"] = _to_int(settings.get("starting_life", 0))
	normalized["settings"] = settings

	var players_value: Variant = normalized.get("players", [])
	var players: Array = players_value if typeof(players_value) == TYPE_ARRAY else []
	for i: int in range(players.size()):
		var player_value: Variant = players[i]
		if typeof(player_value) != TYPE_DICTIONARY:
			continue
		var player: Dictionary = player_value
		player["life"] = _to_int(player.get("life", 0))

		var damage_value: Variant = player.get("commander_damage", {})
		if typeof(damage_value) == TYPE_DICTIONARY:
			var damage: Dictionary = damage_value
			for key: Variant in damage.keys():
				damage[key] = _to_int(damage.get(key, 0))
			player["commander_damage"] = damage
		players[i] = player

	normalized["players"] = players
	return normalized
