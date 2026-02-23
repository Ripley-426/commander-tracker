extends Control

@onready var name_label: Label = $NameLabel
@onready var winner_badge_label: Label = $WinnerBadgeLabel

var player_index: int = -1
var roll_value: int = 1
var die_color: Color = Color(0.10, 0.10, 0.10, 1.0)
var is_winner: bool = false
var is_compact: bool = false
var winner_pulse_tween: Tween = null

func _ready() -> void:
	_update_pivot_to_center()

func setup(p_player_index: int, p_player_name: String, p_die_color: Color, compact: bool = false) -> void:
	player_index = p_player_index
	name_label.text = p_player_name
	die_color = p_die_color
	set_compact(compact)
	set_winner(false)
	set_roll_value(1)

func set_roll_value(value: int) -> void:
	roll_value = clampi(value, 1, 6)
	queue_redraw()

func set_winner(next_is_winner: bool) -> void:
	is_winner = next_is_winner
	winner_badge_label.visible = is_winner
	if is_winner:
		_start_winner_pulse()
	else:
		_stop_winner_pulse()
	queue_redraw()

func set_compact(compact: bool) -> void:
	is_compact = compact
	custom_minimum_size = Vector2(129.0, 162.0) if compact else Vector2(188.0, 245.0)
	name_label.add_theme_font_size_override("font_size", 22 if compact else 30)
	winner_badge_label.add_theme_font_size_override("font_size", 18 if compact else 22)
	queue_redraw()

func _start_winner_pulse() -> void:
	_stop_winner_pulse()
	winner_pulse_tween = create_tween()
	winner_pulse_tween.set_loops()
	winner_pulse_tween.tween_property(self, "scale", Vector2(1.08, 1.08), 0.6)
	winner_pulse_tween.tween_property(self, "scale", Vector2.ONE, 0.6)

func _stop_winner_pulse() -> void:
	if winner_pulse_tween != null and winner_pulse_tween.is_valid():
		winner_pulse_tween.kill()
	winner_pulse_tween = null
	scale = Vector2.ONE

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_update_pivot_to_center()

func _update_pivot_to_center() -> void:
	pivot_offset = size * 0.5

func _draw() -> void:
	var die_rect: Rect2 = _get_die_rect()
	var style_box: StyleBoxFlat = StyleBoxFlat.new()
	style_box.bg_color = die_color
	style_box.corner_radius_top_left = 16
	style_box.corner_radius_top_right = 16
	style_box.corner_radius_bottom_right = 16
	style_box.corner_radius_bottom_left = 16
	style_box.border_width_left = 3
	style_box.border_width_top = 3
	style_box.border_width_right = 3
	style_box.border_width_bottom = 3
	style_box.border_color = Color(1.0, 0.86, 0.24, 1.0) if is_winner else Color(1.0, 1.0, 1.0, 0.18)
	draw_style_box(style_box, die_rect)

	var pip_radius: float = max(4.0, min(die_rect.size.x, die_rect.size.y) * 0.08)
	for pip_position: Vector2 in _get_pip_positions(die_rect, roll_value):
		draw_circle(pip_position, pip_radius, Color(0.98, 0.98, 0.98, 1.0))

func _get_die_rect() -> Rect2:
	var margin: float = 11.0 if is_compact else 15.0
	var reserved_bottom: float = 50.0 if is_compact else 66.0
	return Rect2(
		Vector2(margin, margin),
		Vector2(max(size.x - margin * 2.0, 24.0), max(size.y - reserved_bottom - margin, 24.0))
	)

func _get_pip_positions(die_rect: Rect2, value: int) -> Array[Vector2]:
	var left: float = die_rect.position.x + die_rect.size.x * 0.28
	var right: float = die_rect.position.x + die_rect.size.x * 0.72
	var center_x: float = die_rect.position.x + die_rect.size.x * 0.50
	var top: float = die_rect.position.y + die_rect.size.y * 0.28
	var middle: float = die_rect.position.y + die_rect.size.y * 0.50
	var bottom: float = die_rect.position.y + die_rect.size.y * 0.72

	match value:
		1:
			return [Vector2(center_x, middle)]
		2:
			return [Vector2(left, top), Vector2(right, bottom)]
		3:
			return [Vector2(left, top), Vector2(center_x, middle), Vector2(right, bottom)]
		4:
			return [Vector2(left, top), Vector2(right, top), Vector2(left, bottom), Vector2(right, bottom)]
		5:
			return [Vector2(left, top), Vector2(right, top), Vector2(center_x, middle), Vector2(left, bottom), Vector2(right, bottom)]
		6:
			return [
				Vector2(left, top),
				Vector2(left, middle),
				Vector2(left, bottom),
				Vector2(right, top),
				Vector2(right, middle),
				Vector2(right, bottom)
			]
	return [Vector2(center_x, middle)]
