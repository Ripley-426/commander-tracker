extends RefCounted

static func get_slots(layout_id: String, player_count: int) -> Array[Dictionary]:
	var registry_script: GDScript = load("res://scripts/domain/layout_registry.gd")
	return registry_script.get_slots(layout_id, player_count)
