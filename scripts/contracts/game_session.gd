extends RefCounted
class_name GameSession

func has_active_game() -> bool:
	push_error("GameSession.has_active_game not implemented.")
	return false

func load_active_game() -> Dictionary:
	push_error("GameSession.load_active_game not implemented.")
	return {}

func save_state(_state: Dictionary) -> bool:
	push_error("GameSession.save_state not implemented.")
	return false

func describe_settings(_state: Dictionary) -> String:
	push_error("GameSession.describe_settings not implemented.")
	return ""

func apply_life_delta(_state: Dictionary, _player_index: int, _delta: int) -> bool:
	push_error("GameSession.apply_life_delta not implemented.")
	return false

func apply_commander_delta(_state: Dictionary, _source_index: int, _target_index: int, _delta: int) -> bool:
	push_error("GameSession.apply_commander_delta not implemented.")
	return false
