extends RefCounted
class_name GameStore

func has_active_game() -> bool:
	push_error("GameStore.has_active_game not implemented.")
	return false

func load_active_game() -> Dictionary:
	push_error("GameStore.load_active_game not implemented.")
	return {}

func save_active_game(_data: Dictionary) -> bool:
	push_error("GameStore.save_active_game not implemented.")
	return false

func clear_active_game() -> void:
	push_error("GameStore.clear_active_game not implemented.")
