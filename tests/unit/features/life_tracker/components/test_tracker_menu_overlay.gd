extends GutTest

var main_menu_requests: int = 0
var new_game_requests: int = 0

func _on_main_menu_requested() -> void:
	main_menu_requests += 1

func _on_new_game_requested() -> void:
	new_game_requests += 1

func before_each() -> void:
	main_menu_requests = 0
	new_game_requests = 0

func test_menu_starts_closed() -> void:
	var scene: PackedScene = load("res://scenes/features/life_tracker/components/tracker_menu_overlay.tscn")
	var overlay: Control = scene.instantiate()
	add_child_autofree(overlay)

	var menu_panel: Control = overlay.get_node("MenuPanel")
	var blocker: Control = overlay.get_node("InputBlocker")
	assert_false(menu_panel.visible)
	assert_eq(blocker.mouse_filter, Control.MOUSE_FILTER_IGNORE)

func test_toggle_button_opens_and_closes_menu() -> void:
	var scene: PackedScene = load("res://scenes/features/life_tracker/components/tracker_menu_overlay.tscn")
	var overlay: Control = scene.instantiate()
	add_child_autofree(overlay)

	var menu_button: Button = overlay.get_node("MenuButton")
	var menu_panel: Control = overlay.get_node("MenuPanel")
	var blocker: Control = overlay.get_node("InputBlocker")

	menu_button.pressed.emit()
	assert_true(menu_panel.visible)
	assert_eq(blocker.mouse_filter, Control.MOUSE_FILTER_STOP)

	menu_button.pressed.emit()
	assert_false(menu_panel.visible)
	assert_eq(blocker.mouse_filter, Control.MOUSE_FILTER_IGNORE)

func test_action_buttons_emit_signals_and_close_menu() -> void:
	var scene: PackedScene = load("res://scenes/features/life_tracker/components/tracker_menu_overlay.tscn")
	var overlay: Control = scene.instantiate()
	add_child_autofree(overlay)
	overlay.connect("main_menu_requested", Callable(self, "_on_main_menu_requested"))
	overlay.connect("new_game_requested", Callable(self, "_on_new_game_requested"))

	var menu_button: Button = overlay.get_node("MenuButton")
	var menu_panel: Control = overlay.get_node("MenuPanel")
	var main_menu_action_button: Button = overlay.get_node("MenuPanel/MenuPanelMargin/MenuActions/MainMenuActionButton")
	var new_game_action_button: Button = overlay.get_node("MenuPanel/MenuPanelMargin/MenuActions/NewGameActionButton")

	menu_button.pressed.emit()
	assert_true(menu_panel.visible)
	main_menu_action_button.pressed.emit()
	assert_eq(main_menu_requests, 1)
	assert_false(menu_panel.visible)

	menu_button.pressed.emit()
	assert_true(menu_panel.visible)
	new_game_action_button.pressed.emit()
	assert_eq(new_game_requests, 1)
	assert_false(menu_panel.visible)
