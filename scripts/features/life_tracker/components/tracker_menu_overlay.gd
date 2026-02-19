extends Control

signal main_menu_requested()
signal new_game_requested()
signal menu_opened_changed(is_open: bool)

@onready var input_blocker: Control = $InputBlocker
@onready var menu_panel: Control = $MenuPanel
@onready var menu_button: Button = $MenuButton
@onready var main_menu_action_button: Button = $MenuPanel/MenuPanelMargin/MenuActions/MainMenuActionButton
@onready var new_game_action_button: Button = $MenuPanel/MenuPanelMargin/MenuActions/NewGameActionButton

var is_menu_open: bool = false

func _ready() -> void:
	menu_button.pressed.connect(_on_menu_toggle_pressed)
	main_menu_action_button.pressed.connect(_on_main_menu_action_pressed)
	new_game_action_button.pressed.connect(_on_new_game_action_pressed)
	_apply_menu_button_style()
	set_menu_open(false)

func set_menu_open(open: bool) -> void:
	if is_menu_open == open:
		return
	is_menu_open = open
	menu_panel.visible = open
	input_blocker.mouse_filter = Control.MOUSE_FILTER_STOP if open else Control.MOUSE_FILTER_IGNORE
	menu_opened_changed.emit(is_menu_open)

func close_menu() -> void:
	set_menu_open(false)

func _on_menu_toggle_pressed() -> void:
	set_menu_open(not is_menu_open)

func _on_main_menu_action_pressed() -> void:
	set_menu_open(false)
	main_menu_requested.emit()

func _on_new_game_action_pressed() -> void:
	set_menu_open(false)
	new_game_requested.emit()

func _apply_menu_button_style() -> void:
	var normal_style: StyleBoxFlat = StyleBoxFlat.new()
	normal_style.bg_color = Color(0.10, 0.10, 0.10, 1.0)
	normal_style.corner_radius_top_left = 30
	normal_style.corner_radius_top_right = 30
	normal_style.corner_radius_bottom_left = 30
	normal_style.corner_radius_bottom_right = 30
	normal_style.shadow_color = Color(0.0, 0.0, 0.0, 0.35)
	normal_style.shadow_size = 6

	var hover_style: StyleBoxFlat = normal_style.duplicate() as StyleBoxFlat
	hover_style.bg_color = Color(0.15, 0.15, 0.15, 1.0)

	var pressed_style: StyleBoxFlat = normal_style.duplicate() as StyleBoxFlat
	pressed_style.bg_color = Color(0.07, 0.07, 0.07, 1.0)
	pressed_style.shadow_size = 2

	menu_button.add_theme_stylebox_override("normal", normal_style)
	menu_button.add_theme_stylebox_override("hover", hover_style)
	menu_button.add_theme_stylebox_override("pressed", pressed_style)
	menu_button.add_theme_stylebox_override("disabled", normal_style.duplicate() as StyleBoxFlat)
	menu_button.add_theme_stylebox_override("focus", hover_style.duplicate() as StyleBoxFlat)
