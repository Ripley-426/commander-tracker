extends PanelContainer
class_name PlayerPanel

signal life_delta_requested(player_index: int, delta: int)

@onready var name_label: Label = $MiddleArea/NameLabel
@onready var life_label: Label = $MiddleArea/LifeLabel

var player_index: int = -1
var is_rotated_180: bool = false

func _ready() -> void:
	_refresh_dynamic_text_size()

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_refresh_dynamic_text_size()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_event: InputEventMouseButton = event
		if mouse_event.button_index == MOUSE_BUTTON_LEFT and mouse_event.pressed:
			if size.y <= 0.0:
				return
			var local_y: float = mouse_event.position.y / size.y
			tap_at_normalized_y(local_y)

func setup(index: int, player_name: String, life: int, panel_color: Color, rotate_180: bool = false) -> void:
	player_index = index
	is_rotated_180 = rotate_180
	name_label.text = player_name
	life_label.text = str(life)
	_apply_panel_color(panel_color)
	_apply_rotation(rotate_180)

func tap_at_normalized_y(local_y_normalized: float) -> void:
	if local_y_normalized < 0.5:
		life_delta_requested.emit(player_index, 1)
	else:
		life_delta_requested.emit(player_index, -1)

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
