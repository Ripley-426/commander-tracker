extends Panel

const COMMANDER_DAMAGE_ROW_SCENE: PackedScene = preload("res://scenes/features/life_tracker/components/commander_damage_row.tscn")

signal life_delta_requested(player_index: int, delta: int)
signal commander_delta_requested(target_player_index: int, source_player_index: int, delta: int)

@onready var name_label: Label = $MiddleArea/NameLabel
@onready var life_label: Label = $MiddleArea/LifeLabel
@onready var delta_label: Label = $MiddleArea/DeltaLabel
@onready var top_hit_button: Button = $HitZones/TopHitButton
@onready var bottom_hit_button: Button = $HitZones/BottomHitButton
@onready var commander_damage_root: Control = $CommanderDamageContainer
@onready var commander_damage_container: VBoxContainer = $CommanderDamageContainer/CommanderDamageList
@onready var delta_reset_timer: Timer = $DeltaResetTimer

var player_index: int = -1
var is_rotated_180: bool = false
var pending_delta: int = 0
var commander_damage_labels_by_source: Dictionary = {}

func _ready() -> void:
	top_hit_button.pressed.connect(_on_top_hit_pressed)
	bottom_hit_button.pressed.connect(_on_bottom_hit_pressed)
	delta_reset_timer.timeout.connect(_on_delta_reset_timeout)
	_apply_hit_zone_styles(top_hit_button)
	_apply_hit_zone_styles(bottom_hit_button)
	_prepare_commander_root_layout()
	_refresh_delta_label()
	_refresh_dynamic_text_size()

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_refresh_dynamic_text_size()
		_layout_commander_container()

func setup(index: int, player_name: String, life: int, panel_color: Color, rotate_180: bool = false, commander_rows: Array[Dictionary] = []) -> void:
	player_index = index
	is_rotated_180 = rotate_180
	name_label.text = player_name
	life_label.text = str(life)
	_apply_panel_color(panel_color)
	_apply_rotation(rotate_180)
	_rebuild_commander_rows(commander_rows)

func set_life(life: int) -> void:
	life_label.text = str(life)

func add_life_delta_feedback(delta: int) -> void:
	if delta == 0:
		return
	_register_delta(delta)

func set_commander_damage(source_player_index: int, damage: int) -> void:
	var key: String = str(source_player_index)
	if not commander_damage_labels_by_source.has(key):
		return
	var label: Label = commander_damage_labels_by_source[key]
	label.text = str(max(damage, 0))

func _on_top_hit_pressed() -> void:
	_register_delta(1)
	life_delta_requested.emit(player_index, 1)

func _on_bottom_hit_pressed() -> void:
	_register_delta(-1)
	life_delta_requested.emit(player_index, -1)

func _on_commander_plus_pressed(source_player_index: int) -> void:
	commander_delta_requested.emit(player_index, source_player_index, 1)

func _on_commander_minus_pressed(source_player_index: int) -> void:
	commander_delta_requested.emit(player_index, source_player_index, -1)

func _register_delta(delta: int) -> void:
	pending_delta += delta
	_refresh_delta_label()
	delta_reset_timer.start()

func _refresh_delta_label() -> void:
	if pending_delta == 0:
		delta_label.visible = false
		delta_label.text = "+0"
		return

	delta_label.visible = true
	delta_label.text = "%+d" % pending_delta

func _on_delta_reset_timeout() -> void:
	pending_delta = 0
	_refresh_delta_label()

func _rebuild_commander_rows(commander_rows: Array[Dictionary]) -> void:
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
		row.connect("delta_requested", Callable(self, "_on_commander_row_delta_requested"))
		var damage_label: Label = row.get_node("DamageLabel")
		commander_damage_labels_by_source[str(source_player_index)] = damage_label

	commander_damage_container.visible = commander_damage_container.get_child_count() > 0
	call_deferred("_layout_commander_container")

func _on_commander_row_delta_requested(source_player_index: int, delta: int) -> void:
	if delta > 0:
		_on_commander_plus_pressed(source_player_index)
		return
	_on_commander_minus_pressed(source_player_index)

func _clear_children(node: Node) -> void:
	for child: Node in node.get_children():
		child.queue_free()

func _layout_commander_container() -> void:
	if commander_damage_root == null:
		return

	var inner_margin_left: float = 8.0
	var inner_margin_top: float = 8.0
	var inner_margin_right: float = 4.0
	var inner_margin_bottom: float = 4.0
	var margin_left: float = 18.0
	var margin_bottom: float = 16.0
	var content_size: Vector2 = _measure_commander_content_size()
	var target_width: float = max(content_size.x + inner_margin_left + inner_margin_right, 96.0)
	var target_height: float = content_size.y + inner_margin_top + inner_margin_bottom
	var top_y: float = max(size.y - margin_bottom - target_height, 0.0)

	commander_damage_root.position = Vector2(margin_left, top_y)
	commander_damage_root.size = Vector2(target_width, target_height)

func _measure_commander_content_size() -> Vector2:
	var row_count: int = commander_damage_container.get_child_count()
	if row_count <= 0:
		return Vector2(96.0, 0.0)

	var row_spacing: float = float(commander_damage_container.get_theme_constant("separation"))
	var total_height: float = 0.0
	var max_width: float = 0.0

	for i: int in range(row_count):
		var row_node: Node = commander_damage_container.get_child(i)
		if row_node == null:
			continue
		var row_control: Control = row_node as Control
		if row_control == null:
			continue
		var row_size: Vector2 = row_control.get_combined_minimum_size()
		total_height += row_size.y
		max_width = max(max_width, row_size.x)

	if row_count > 1:
		total_height += row_spacing * float(row_count - 1)

	return Vector2(max_width, total_height)

func _prepare_commander_root_layout() -> void:
	if commander_damage_root == null:
		return
	commander_damage_root.anchor_left = 0.0
	commander_damage_root.anchor_top = 0.0
	commander_damage_root.anchor_right = 0.0
	commander_damage_root.anchor_bottom = 0.0
	commander_damage_root.offset_left = 0.0
	commander_damage_root.offset_top = 0.0
	commander_damage_root.offset_right = 0.0
	commander_damage_root.offset_bottom = 0.0
	commander_damage_root.custom_minimum_size = Vector2.ZERO

func _apply_hit_zone_styles(hit_button: Button) -> void:
	var normal_style: StyleBoxFlat = StyleBoxFlat.new()
	normal_style.bg_color = Color(1.0, 1.0, 1.0, 0.0)
	normal_style.shadow_color = Color(0.0, 0.0, 0.0, 0.0)
	normal_style.shadow_size = 0

	var hover_style: StyleBoxFlat = normal_style.duplicate() as StyleBoxFlat
	hover_style.bg_color = Color(1.0, 1.0, 1.0, 0.06)

	var pressed_style: StyleBoxFlat = normal_style.duplicate() as StyleBoxFlat
	pressed_style.bg_color = Color(1.0, 1.0, 1.0, 0.24)
	pressed_style.shadow_color = Color(0.0, 0.0, 0.0, 0.34)
	pressed_style.shadow_size = 10

	var disabled_style: StyleBoxFlat = normal_style.duplicate() as StyleBoxFlat
	var focus_style: StyleBoxFlat = hover_style.duplicate() as StyleBoxFlat

	hit_button.add_theme_stylebox_override("normal", normal_style)
	hit_button.add_theme_stylebox_override("hover", hover_style)
	hit_button.add_theme_stylebox_override("pressed", pressed_style)
	hit_button.add_theme_stylebox_override("disabled", disabled_style)
	hit_button.add_theme_stylebox_override("focus", focus_style)

func _apply_panel_color(panel_color: Color) -> void:
	var panel_style: StyleBoxFlat = StyleBoxFlat.new()
	panel_style.bg_color = panel_color
	panel_style.corner_radius_top_left = 0
	panel_style.corner_radius_top_right = 0
	panel_style.corner_radius_bottom_right = 0
	panel_style.corner_radius_bottom_left = 0
	add_theme_stylebox_override("panel", panel_style)

func _apply_rotation(rotate_180: bool) -> void:
	rotation_degrees = 180.0 if rotate_180 else 0.0
	call_deferred("_update_pivot_for_rotation")

func _update_pivot_for_rotation() -> void:
	pivot_offset = size * 0.5

func _refresh_dynamic_text_size() -> void:
	if life_label == null:
		return
	var computed_size: int = int(round(size.y * 0.34))
	var clamped_size: int = clampi(computed_size, 42, 180)
	life_label.add_theme_font_size_override("font_size", clamped_size)
