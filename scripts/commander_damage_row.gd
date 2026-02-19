extends HBoxContainer
class_name CommanderDamageRow

signal delta_requested(source_player_index: int, delta: int)

@onready var minus_button: Button = $MinusButton
@onready var damage_label: Label = $DamageLabel
@onready var plus_button: Button = $PlusButton

var source_player_index: int = -1

func _ready() -> void:
	minus_button.pressed.connect(_on_minus_pressed)
	plus_button.pressed.connect(_on_plus_pressed)

func setup(p_source_player_index: int, damage: int, source_color: Color) -> void:
	source_player_index = p_source_player_index
	name = "Source_%d" % source_player_index
	set_damage(damage)
	_apply_button_style(minus_button, source_color)
	_apply_button_style(plus_button, source_color)

func set_damage(damage: int) -> void:
	damage_label.text = str(max(damage, 0))

func _on_plus_pressed() -> void:
	delta_requested.emit(source_player_index, 1)

func _on_minus_pressed() -> void:
	delta_requested.emit(source_player_index, -1)

func _apply_button_style(button: Button, button_color: Color) -> void:
	var normal_style: StyleBoxFlat = StyleBoxFlat.new()
	normal_style.bg_color = button_color
	normal_style.shadow_color = Color(0.0, 0.0, 0.0, 0.25)
	normal_style.shadow_size = 2
	normal_style.corner_radius_top_left = 6
	normal_style.corner_radius_top_right = 6
	normal_style.corner_radius_bottom_left = 6
	normal_style.corner_radius_bottom_right = 6
	normal_style.content_margin_left = 2.0
	normal_style.content_margin_right = 2.0
	normal_style.content_margin_top = 1.0
	normal_style.content_margin_bottom = 1.0

	var hover_style: StyleBoxFlat = normal_style.duplicate() as StyleBoxFlat
	hover_style.bg_color = button_color.lightened(0.10)

	var pressed_style: StyleBoxFlat = normal_style.duplicate() as StyleBoxFlat
	pressed_style.bg_color = button_color.darkened(0.15)
	pressed_style.shadow_size = 0

	button.add_theme_stylebox_override("normal", normal_style)
	button.add_theme_stylebox_override("hover", hover_style)
	button.add_theme_stylebox_override("pressed", pressed_style)
	button.add_theme_stylebox_override("disabled", normal_style.duplicate() as StyleBoxFlat)
	button.add_theme_stylebox_override("focus", hover_style.duplicate() as StyleBoxFlat)
