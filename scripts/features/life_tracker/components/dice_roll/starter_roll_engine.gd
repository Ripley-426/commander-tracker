extends RefCounted

var forced_roll_values: Array[int] = []
var random: RandomNumberGenerator = RandomNumberGenerator.new()

func _init() -> void:
	random.randomize()

func set_forced_roll_values(values: Array[int]) -> void:
	forced_roll_values = values.duplicate()

func roll_round(candidate_players: Array[Dictionary]) -> Dictionary:
	var round_results: Dictionary = {}
	var highest_roll: int = 0

	for player_data: Dictionary in candidate_players:
		var player_index: int = int(player_data.get("player_index", -1))
		var key: String = str(player_index)
		var roll_value: int = _roll_value()
		round_results[key] = roll_value
		highest_roll = maxi(highest_roll, roll_value)

	var tied_players: Array[Dictionary] = []
	for player_data: Dictionary in candidate_players:
		var player_index: int = int(player_data.get("player_index", -1))
		var key: String = str(player_index)
		if int(round_results.get(key, 0)) == highest_roll:
			tied_players.append(player_data)

	var winner_player_index: int = -1
	if tied_players.size() == 1:
		winner_player_index = int(tied_players[0].get("player_index", -1))

	return {
		"round_results": round_results,
		"highest_roll": highest_roll,
		"tied_players": tied_players,
		"winner_player_index": winner_player_index
	}

func _roll_value() -> int:
	if forced_roll_values.size() > 0:
		return clampi(int(forced_roll_values.pop_front()), 1, 6)
	return random.randi_range(1, 6)
