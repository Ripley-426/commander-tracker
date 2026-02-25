extends RefCounted

static func get_slots(layout_id: String, player_count: int, is_portrait: bool = false) -> Array[Dictionary]:
	var registry_script: GDScript = load("res://scripts/domain/layout_registry.gd")
	return registry_script.get_slots(layout_id, player_count, is_portrait)
