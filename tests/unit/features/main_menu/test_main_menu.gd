extends GutTest

class FakeStore extends "res://scripts/contracts/game_store.gd":
	var has_game: bool = false

	func _init(p_has_game: bool = false) -> void:
		has_game = p_has_game

	func has_active_game() -> bool:
		return has_game

func test_refresh_buttons_hides_continue_without_active_game() -> void:
	var scene: PackedScene = load("res://scenes/features/main_menu/main_menu.tscn")
	var menu: Control = scene.instantiate()
	add_child_autofree(menu)

	menu.store = FakeStore.new(false)
	menu._refresh_buttons()

	var continue_button: Button = menu.get_node("CenterContainer/VBoxContainer/ContinueButton")
	assert_false(continue_button.visible)
	assert_true(continue_button.disabled)

func test_refresh_buttons_shows_continue_with_active_game() -> void:
	var scene: PackedScene = load("res://scenes/features/main_menu/main_menu.tscn")
	var menu: Control = scene.instantiate()
	add_child_autofree(menu)

	menu.store = FakeStore.new(true)
	menu._refresh_buttons()

	var continue_button: Button = menu.get_node("CenterContainer/VBoxContainer/ContinueButton")
	assert_true(continue_button.visible)
	assert_false(continue_button.disabled)

