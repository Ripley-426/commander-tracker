extends Control

signal main_menu_requested()
signal new_game_requested()
signal starter_roll_requested()
signal menu_opened_changed(is_open: bool)

enum MenuState {
	CLOSED,
	OPENING,
	OPEN,
	CLOSING
}

const TRANSITION_DURATION_SEC: float = 0.5

@onready var input_blocker: Control = $InputBlocker
@onready var reveal_layer: Control = $RevealLayer
@onready var menu_panel: Control = $MenuPanel
@onready var menu_actions: VBoxContainer = $MenuPanel/MenuPanelMargin/MenuActions
@onready var menu_title: Label = $MenuPanel/MenuPanelMargin/MenuActions/MenuTitle
@onready var menu_button: Button = $MenuButton
@onready var main_menu_action_button: Button = $MenuPanel/MenuPanelMargin/MenuActions/MainMenuActionButton
@onready var new_game_action_button: Button = $MenuPanel/MenuPanelMargin/MenuActions/NewGameActionButton
@onready var roll_starter_action_button: Button = $MenuPanel/MenuPanelMargin/MenuActions/RollStarterActionButton

var is_menu_open: bool = false
var state: MenuState = MenuState.CLOSED
var transition_progress: float = 0.0
var transition_target: float = 0.0
var menu_button_black_style: StyleBoxFlat = StyleBoxFlat.new()
var menu_button_black_hover_style: StyleBoxFlat = StyleBoxFlat.new()
var menu_button_black_pressed_style: StyleBoxFlat = StyleBoxFlat.new()
var menu_button_clear_style: StyleBoxFlat = StyleBoxFlat.new()

func _ready() -> void:
	menu_button.pressed.connect(_on_menu_toggle_pressed)
	main_menu_action_button.pressed.connect(_on_main_menu_action_pressed)
	new_game_action_button.pressed.connect(_on_new_game_action_pressed)
	roll_starter_action_button.pressed.connect(_on_roll_starter_action_pressed)
	_apply_menu_button_style()
	_apply_menu_action_styles()
	set_process(false)
	set_menu_open(false)

func _process(delta: float) -> void:
	if is_equal_approx(transition_progress, transition_target):
		_finish_transition()
		return

	var direction: float = 1.0 if transition_target > transition_progress else -1.0
	transition_progress += direction * (delta / TRANSITION_DURATION_SEC)
	if direction > 0.0:
		transition_progress = min(transition_progress, transition_target)
	else:
		transition_progress = max(transition_progress, transition_target)
	_apply_transition_visuals()

	if is_equal_approx(transition_progress, transition_target):
		_finish_transition()

func set_menu_open(open: bool) -> void:
	transition_target = 1.0 if open else 0.0
	transition_progress = transition_target
	_apply_transition_visuals()
	if open:
		_finalize_open()
	else:
		_finalize_closed()

func close_menu() -> void:
	set_menu_open(false)

func set_menu_colors(colors: Array[Color]) -> void:
	# Intentionally unused; center button is transparent and reveals real board colors.
	if colors.size() >= 0:
		pass

func _on_menu_toggle_pressed() -> void:
	if state == MenuState.OPEN or state == MenuState.OPENING:
		_start_transition_to(false)
		return
	_start_transition_to(true)

func _on_main_menu_action_pressed() -> void:
	if _is_transitioning():
		return
	set_menu_open(false)
	main_menu_requested.emit()

func _on_new_game_action_pressed() -> void:
	if _is_transitioning():
		return
	set_menu_open(false)
	new_game_requested.emit()

func _on_roll_starter_action_pressed() -> void:
	if _is_transitioning():
		return
	set_menu_open(false)
	starter_roll_requested.emit()

func _start_transition_to(open: bool) -> void:
	transition_target = 1.0 if open else 0.0
	state = MenuState.OPENING if open else MenuState.CLOSING
	menu_panel.visible = true
	reveal_layer.visible = true
	_set_menu_button_transparent(true)
	input_blocker.mouse_filter = Control.MOUSE_FILTER_STOP
	_set_menu_actions_enabled(false)
	set_process(true)
	_apply_transition_visuals()

func _finish_transition() -> void:
	if transition_target >= 1.0:
		_finalize_open()
		return
	_finalize_closed()

func _finalize_open() -> void:
	set_process(false)
	state = MenuState.OPEN
	is_menu_open = true
	menu_panel.visible = true
	reveal_layer.visible = true
	_set_menu_button_transparent(true)
	input_blocker.mouse_filter = Control.MOUSE_FILTER_STOP
	_set_menu_actions_enabled(true)
	menu_opened_changed.emit(true)

func _finalize_closed() -> void:
	set_process(false)
	state = MenuState.CLOSED
	is_menu_open = false
	menu_panel.visible = false
	reveal_layer.visible = false
	_set_menu_button_transparent(false)
	input_blocker.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_set_menu_actions_enabled(false)
	menu_opened_changed.emit(false)

func _apply_transition_visuals() -> void:
	var visual_progress: float = _get_visual_progress()
	var center: Vector2 = _get_menu_button_center()
	var hole_radius: float = (min(menu_button.size.x, menu_button.size.y) * 0.5) - 2.0
	reveal_layer.call("set_reveal", visual_progress, center, hole_radius)

	var content_alpha: float = ease(clampf((visual_progress - 0.58) / 0.42, 0.0, 1.0), 0.6)
	menu_panel.modulate.a = content_alpha
	menu_actions.modulate.a = content_alpha
	menu_title.modulate.a = content_alpha
	var content_scale: float = lerpf(0.92, 1.0, content_alpha)
	menu_actions.scale = Vector2(content_scale, content_scale)

func _get_visual_progress() -> float:
	if state == MenuState.OPENING:
		return _ease_out_cubic(transition_progress)
	if state == MenuState.CLOSING:
		var closed_progress: float = 1.0 - transition_progress
		return 1.0 - _ease_in_cubic(closed_progress)
	return transition_progress

func _ease_out_cubic(value: float) -> float:
	var t: float = clampf(value, 0.0, 1.0)
	return 1.0 - pow(1.0 - t, 3.0)

func _ease_in_cubic(value: float) -> float:
	var t: float = clampf(value, 0.0, 1.0)
	return pow(t, 3.0)

func _is_transitioning() -> bool:
	return state == MenuState.OPENING or state == MenuState.CLOSING

func _get_menu_button_center() -> Vector2:
	return menu_button.global_position + (menu_button.size * 0.5)

func _set_menu_actions_enabled(enabled: bool) -> void:
	main_menu_action_button.disabled = not enabled
	new_game_action_button.disabled = not enabled
	roll_starter_action_button.disabled = not enabled

func _apply_menu_button_style() -> void:
	var corner_radius: int = int(round(menu_button.size.y * 0.5))
	menu_button_black_style.bg_color = Color(0.08, 0.08, 0.08, 1.0)
	menu_button_black_style.corner_radius_top_left = corner_radius
	menu_button_black_style.corner_radius_top_right = corner_radius
	menu_button_black_style.corner_radius_bottom_left = corner_radius
	menu_button_black_style.corner_radius_bottom_right = corner_radius
	menu_button_black_style.shadow_color = Color(0.0, 0.0, 0.0, 0.35)
	menu_button_black_style.shadow_size = max(6, int(round(menu_button.size.y * 0.1)))

	menu_button_black_hover_style = menu_button_black_style.duplicate() as StyleBoxFlat
	menu_button_black_hover_style.bg_color = Color(0.15, 0.15, 0.15, 1.0)

	menu_button_black_pressed_style = menu_button_black_style.duplicate() as StyleBoxFlat
	menu_button_black_pressed_style.bg_color = Color(0.05, 0.05, 0.05, 1.0)
	menu_button_black_pressed_style.shadow_size = 2

	menu_button_clear_style.bg_color = Color(0.0, 0.0, 0.0, 0.0)
	menu_button_clear_style.corner_radius_top_left = corner_radius
	menu_button_clear_style.corner_radius_top_right = corner_radius
	menu_button_clear_style.corner_radius_bottom_left = corner_radius
	menu_button_clear_style.corner_radius_bottom_right = corner_radius
	menu_button_clear_style.shadow_color = Color(0.0, 0.0, 0.0, 0.0)
	menu_button_clear_style.shadow_size = 0

	_set_menu_button_transparent(false)

func _set_menu_button_transparent(transparent: bool) -> void:
	if transparent:
		menu_button.add_theme_stylebox_override("normal", menu_button_clear_style)
		menu_button.add_theme_stylebox_override("hover", menu_button_clear_style.duplicate() as StyleBoxFlat)
		menu_button.add_theme_stylebox_override("pressed", menu_button_clear_style.duplicate() as StyleBoxFlat)
		menu_button.add_theme_stylebox_override("disabled", menu_button_clear_style.duplicate() as StyleBoxFlat)
		menu_button.add_theme_stylebox_override("focus", menu_button_clear_style.duplicate() as StyleBoxFlat)
		return
	menu_button.add_theme_stylebox_override("normal", menu_button_black_style)
	menu_button.add_theme_stylebox_override("hover", menu_button_black_hover_style)
	menu_button.add_theme_stylebox_override("pressed", menu_button_black_pressed_style)
	menu_button.add_theme_stylebox_override("disabled", menu_button_black_style.duplicate() as StyleBoxFlat)
	menu_button.add_theme_stylebox_override("focus", menu_button_black_hover_style.duplicate() as StyleBoxFlat)

func _apply_menu_action_styles() -> void:
	_apply_action_button_style(main_menu_action_button, Color(0.86, 0.26, 0.26, 0.92))
	_apply_action_button_style(new_game_action_button, Color(0.22, 0.58, 0.92, 0.92))
	_apply_action_button_style(roll_starter_action_button, Color(0.20, 0.72, 0.40, 0.92))

func _apply_action_button_style(button: Button, base_color: Color) -> void:
	var normal_style: StyleBoxFlat = StyleBoxFlat.new()
	normal_style.bg_color = base_color
	normal_style.corner_radius_top_left = 24
	normal_style.corner_radius_top_right = 24
	normal_style.corner_radius_bottom_left = 24
	normal_style.corner_radius_bottom_right = 24
	normal_style.shadow_color = Color(0.0, 0.0, 0.0, 0.28)
	normal_style.shadow_size = 8

	var hover_style: StyleBoxFlat = normal_style.duplicate() as StyleBoxFlat
	hover_style.bg_color = base_color.lightened(0.08)

	var pressed_style: StyleBoxFlat = normal_style.duplicate() as StyleBoxFlat
	pressed_style.bg_color = base_color.darkened(0.14)
	pressed_style.shadow_size = 3

	var disabled_style: StyleBoxFlat = normal_style.duplicate() as StyleBoxFlat
	disabled_style.bg_color = base_color.darkened(0.32)
	disabled_style.shadow_size = 0

	button.add_theme_stylebox_override("normal", normal_style)
	button.add_theme_stylebox_override("hover", hover_style)
	button.add_theme_stylebox_override("pressed", pressed_style)
	button.add_theme_stylebox_override("disabled", disabled_style)
	button.add_theme_stylebox_override("focus", hover_style.duplicate() as StyleBoxFlat)
