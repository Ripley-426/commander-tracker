extends GutTest

var main_menu_requests: int = 0
var new_game_requests: int = 0
var starter_roll_requests: int = 0

func _on_main_menu_requested() -> void:
	main_menu_requests += 1

func _on_new_game_requested() -> void:
	new_game_requests += 1

func _on_starter_roll_requested() -> void:
	starter_roll_requests += 1

func before_each() -> void:
	main_menu_requests = 0
	new_game_requests = 0
	starter_roll_requests = 0

func _create_overlay() -> Control:
	var scene: PackedScene = load("res://scenes/features/life_tracker/components/menu/tracker_menu_overlay.tscn")
	var overlay: Control = scene.instantiate()
	add_child_autofree(overlay)
	return overlay

func test_menu_starts_closed() -> void:
	var overlay: Control = _create_overlay()
	var menu_panel: Control = overlay.get_node("MenuPanel")
	assert_false(menu_panel.visible)

func test_menu_starts_with_input_blocker_ignoring_input() -> void:
	var overlay: Control = _create_overlay()
	var blocker: Control = overlay.get_node("InputBlocker")
	assert_eq(blocker.mouse_filter, Control.MOUSE_FILTER_IGNORE)

func test_menu_button_size_is_doubled() -> void:
	var overlay: Control = _create_overlay()
	var menu_button: Button = overlay.get_node("MenuButton")
	assert_eq(menu_button.size, Vector2(120.0, 120.0))

func test_toggle_button_opens_menu() -> void:
	var overlay: Control = _create_overlay()
	var menu_button: Button = overlay.get_node("MenuButton")
	var menu_panel: Control = overlay.get_node("MenuPanel")
	menu_button.pressed.emit()
	assert_true(menu_panel.visible)

func test_toggle_button_sets_input_blocker_to_stop_when_open() -> void:
	var overlay: Control = _create_overlay()
	var menu_button: Button = overlay.get_node("MenuButton")
	var blocker: Control = overlay.get_node("InputBlocker")
	menu_button.pressed.emit()
	assert_eq(blocker.mouse_filter, Control.MOUSE_FILTER_STOP)

func test_toggle_button_closes_menu_when_pressed_twice() -> void:
	var overlay: Control = _create_overlay()
	var menu_button: Button = overlay.get_node("MenuButton")
	var menu_panel: Control = overlay.get_node("MenuPanel")
	menu_button.pressed.emit()
	menu_button.pressed.emit()
	assert_false(menu_panel.visible)

func test_toggle_button_sets_input_blocker_to_ignore_when_closed() -> void:
	var overlay: Control = _create_overlay()
	var menu_button: Button = overlay.get_node("MenuButton")
	var blocker: Control = overlay.get_node("InputBlocker")
	menu_button.pressed.emit()
	menu_button.pressed.emit()
	assert_eq(blocker.mouse_filter, Control.MOUSE_FILTER_IGNORE)

func test_main_menu_action_emits_main_menu_signal() -> void:
	var overlay: Control = _create_overlay()
	overlay.connect("main_menu_requested", Callable(self, "_on_main_menu_requested"))

	var menu_button: Button = overlay.get_node("MenuButton")
	var main_menu_action_button: Button = overlay.get_node("MenuPanel/MenuPanelMargin/MenuActions/MainMenuActionButton")
	menu_button.pressed.emit()
	main_menu_action_button.pressed.emit()
	assert_eq(main_menu_requests, 1)

func test_main_menu_action_closes_menu() -> void:
	var overlay: Control = _create_overlay()
	var menu_button: Button = overlay.get_node("MenuButton")
	var menu_panel: Control = overlay.get_node("MenuPanel")
	var main_menu_action_button: Button = overlay.get_node("MenuPanel/MenuPanelMargin/MenuActions/MainMenuActionButton")
	menu_button.pressed.emit()
	main_menu_action_button.pressed.emit()
	assert_false(menu_panel.visible)

func test_new_game_action_emits_new_game_signal() -> void:
	var overlay: Control = _create_overlay()
	overlay.connect("new_game_requested", Callable(self, "_on_new_game_requested"))

	var menu_button: Button = overlay.get_node("MenuButton")
	var new_game_action_button: Button = overlay.get_node("MenuPanel/MenuPanelMargin/MenuActions/NewGameActionButton")
	menu_button.pressed.emit()
	new_game_action_button.pressed.emit()
	assert_eq(new_game_requests, 1)

func test_new_game_action_closes_menu() -> void:
	var overlay: Control = _create_overlay()
	var menu_button: Button = overlay.get_node("MenuButton")
	var menu_panel: Control = overlay.get_node("MenuPanel")
	var new_game_action_button: Button = overlay.get_node("MenuPanel/MenuPanelMargin/MenuActions/NewGameActionButton")
	menu_button.pressed.emit()
	new_game_action_button.pressed.emit()
	assert_false(menu_panel.visible)

func test_roll_starter_action_emits_starter_roll_signal() -> void:
	var overlay: Control = _create_overlay()
	overlay.connect("starter_roll_requested", Callable(self, "_on_starter_roll_requested"))

	var menu_button: Button = overlay.get_node("MenuButton")
	var roll_starter_action_button: Button = overlay.get_node("MenuPanel/MenuPanelMargin/MenuActions/RollStarterActionButton")
	menu_button.pressed.emit()
	roll_starter_action_button.pressed.emit()
	assert_eq(starter_roll_requests, 1)

func test_roll_starter_action_closes_menu() -> void:
	var overlay: Control = _create_overlay()
	var menu_button: Button = overlay.get_node("MenuButton")
	var menu_panel: Control = overlay.get_node("MenuPanel")
	var roll_starter_action_button: Button = overlay.get_node("MenuPanel/MenuPanelMargin/MenuActions/RollStarterActionButton")
	menu_button.pressed.emit()
	roll_starter_action_button.pressed.emit()
	assert_false(menu_panel.visible)
