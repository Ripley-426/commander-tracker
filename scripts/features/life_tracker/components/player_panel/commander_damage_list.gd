extends MarginContainer

const COMMANDER_DAMAGE_ROW_SCENE: PackedScene = preload("res://scenes/features/life_tracker/components/player_panel/commander_damage_row.tscn")
const OPPONENT_ROW_SEPARATION: int = 40

signal delta_requested(source_player_index: int, delta: int)

@onready var commander_damage_container: VBoxContainer = $CommanderDamageList

var commander_damage_labels_by_source: Dictionary = {}

func _ready() -> void:
	# Enforce row spacing in code so it is consistent even if scene/theme overrides differ on device.
	commander_damage_container.add_theme_constant_override("separation", OPPONENT_ROW_SEPARATION)

func setup_rows(commander_rows: Array[Dictionary], is_dead: bool) -> void:
	_clear_children(commander_damage_container)
	commander_damage_labels_by_source.clear()

	for row_data: Dictionary in commander_rows:
		var source_player_index: int = int(row_data.get("source_index", -1))
		if source_player_index < 0:
			continue

		var source_color: Color = row_data.get("source_color", Color(1.0, 1.0, 1.0, 1.0))
		var damage: int = max(int(row_data.get("damage", 0)), 0)
		var row: Control = COMMANDER_DAMAGE_ROW_SCENE.instantiate()
		commander_damage_container.add_child(row)
		row.call("setup", source_player_index, damage, source_color)
		row.connect("delta_requested", Callable(self, "_on_row_delta_requested"))
		var damage_label: Label = row.get_node("DamageLabel")
		commander_damage_labels_by_source[str(source_player_index)] = damage_label

	commander_damage_container.visible = commander_damage_container.get_child_count() > 0
	set_interactable(not is_dead)

func set_damage(source_player_index: int, damage: int) -> void:
	var key: String = str(source_player_index)
	if not commander_damage_labels_by_source.has(key):
		return
	var label: Label = commander_damage_labels_by_source[key]
	label.text = str(max(damage, 0))

func set_interactable(enabled: bool) -> void:
	for row_node: Node in commander_damage_container.get_children():
		row_node.call("set_interactable", enabled)

func layout_for_panel_size(panel_size: Vector2) -> void:
	var inner_margin_left: float = 8.0
	var inner_margin_top: float = 8.0
	var inner_margin_right: float = 4.0
	var inner_margin_bottom: float = 4.0
	var margin_left: float = 18.0
	var margin_bottom: float = 16.0
	var content_size: Vector2 = _measure_commander_content_size()
	var target_width: float = max(content_size.x + inner_margin_left + inner_margin_right, 96.0)
	var target_height: float = content_size.y + inner_margin_top + inner_margin_bottom
	var top_y: float = max(panel_size.y - margin_bottom - target_height, 0.0)

	position = Vector2(margin_left, top_y)
	size = Vector2(target_width, target_height)

func _on_row_delta_requested(source_player_index: int, delta: int) -> void:
	if delta == 0:
		return
	delta_requested.emit(source_player_index, delta)

func _measure_commander_content_size() -> Vector2:
	var row_count: int = commander_damage_container.get_child_count()
	if row_count <= 0:
		return Vector2(96.0, 0.0)

	var row_spacing: float = float(commander_damage_container.get_theme_constant("separation"))
	var total_height: float = 0.0
	var max_width: float = 0.0

	for i: int in range(row_count):
		var row_node: Node = commander_damage_container.get_child(i)
		var row_control: Control = row_node as Control
		if row_control == null:
			continue
		var row_size: Vector2 = row_control.get_combined_minimum_size()
		total_height += row_size.y
		max_width = max(max_width, row_size.x)

	if row_count > 1:
		total_height += row_spacing * float(row_count - 1)

	return Vector2(max_width, total_height)

func _clear_children(node: Node) -> void:
	for child: Node in node.get_children():
		node.remove_child(child)
		child.free()
