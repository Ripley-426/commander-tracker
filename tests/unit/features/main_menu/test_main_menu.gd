extends GutTest

class FakeStore extends "res://scripts/contracts/game_store.gd":
	var has_game: bool = false

	func _init(p_has_game: bool = false) -> void:
		has_game = p_has_game

	func has_active_game() -> bool:
		return has_game

var layout_debug_called: bool = false

func _on_layout_debug_called() -> void:
	layout_debug_called = true

func _create_menu() -> Control:
	var scene: PackedScene = load("res://scenes/features/main_menu/main_menu.tscn")
	var menu: Control = scene.instantiate()
	add_child_autofree(menu)
	return menu

func test_refresh_buttons_hides_continue_without_active_game() -> void:
	var menu: Control = _create_menu()
	menu.store = FakeStore.new(false)
	menu._refresh_buttons()

	var continue_button: Button = menu.get_node("CenterContainer/MarginContainer/VBoxContainer/ContinueButton")
	assert_false(continue_button.visible)

func test_refresh_buttons_disables_continue_without_active_game() -> void:
	var menu: Control = _create_menu()
	menu.store = FakeStore.new(false)
	menu._refresh_buttons()

	var continue_button: Button = menu.get_node("CenterContainer/MarginContainer/VBoxContainer/ContinueButton")
	assert_true(continue_button.disabled)

func test_refresh_buttons_shows_continue_with_active_game() -> void:
	var menu: Control = _create_menu()
	menu.store = FakeStore.new(true)
	menu._refresh_buttons()

	var continue_button: Button = menu.get_node("CenterContainer/MarginContainer/VBoxContainer/ContinueButton")
	assert_true(continue_button.visible)

func test_refresh_buttons_enables_continue_with_active_game() -> void:
	var menu: Control = _create_menu()
	menu.store = FakeStore.new(true)
	menu._refresh_buttons()

	var continue_button: Button = menu.get_node("CenterContainer/MarginContainer/VBoxContainer/ContinueButton")
	assert_false(continue_button.disabled)

func test_layout_debug_button_exists() -> void:
	var menu: Control = _create_menu()
	var layout_debug_button: Button = menu.get_node("CenterContainer/MarginContainer/VBoxContainer/LayoutDebugButton")
	assert_true(layout_debug_button != null)

func test_layout_debug_button_calls_override_handler() -> void:
	var menu: Control = _create_menu()
	layout_debug_called = false
	menu.on_open_layout_debug = Callable(self, "_on_layout_debug_called")
	var layout_debug_button: Button = menu.get_node("CenterContainer/MarginContainer/VBoxContainer/LayoutDebugButton")
	layout_debug_button.pressed.emit()
	assert_true(layout_debug_called)
