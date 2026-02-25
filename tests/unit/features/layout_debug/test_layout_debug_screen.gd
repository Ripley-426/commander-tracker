extends GutTest

func _create_screen() -> Control:
	var scene: PackedScene = load("res://scenes/features/layout_debug/layout_debug.tscn")
	var screen: Control = scene.instantiate()
	add_child_autofree(screen)
	return screen

func test_default_player_count_is_four() -> void:
	var screen: Control = _create_screen()
	var label: Label = screen.get_node("RootMargin/RootVBox/ControlsPanel/ControlsMargin/ControlsHBox/PlayerCountValueLabel")
	assert_eq(label.text, "4")

func test_decrease_button_clamps_at_two() -> void:
	var screen: Control = _create_screen()
	var decrease_button: Button = screen.get_node("RootMargin/RootVBox/ControlsPanel/ControlsMargin/ControlsHBox/DecreaseButton")
	for _i: int in range(10):
		decrease_button.pressed.emit()
	var label: Label = screen.get_node("RootMargin/RootVBox/ControlsPanel/ControlsMargin/ControlsHBox/PlayerCountValueLabel")
	assert_eq(label.text, "2")

func test_increase_button_clamps_at_six() -> void:
	var screen: Control = _create_screen()
	var increase_button: Button = screen.get_node("RootMargin/RootVBox/ControlsPanel/ControlsMargin/ControlsHBox/IncreaseButton")
	for _i: int in range(10):
		increase_button.pressed.emit()
	var label: Label = screen.get_node("RootMargin/RootVBox/ControlsPanel/ControlsMargin/ControlsHBox/PlayerCountValueLabel")
	assert_eq(label.text, "6")

func test_orientation_toggle_updates_label_text() -> void:
	var screen: Control = _create_screen()
	var orientation_button: CheckButton = screen.get_node("RootMargin/RootVBox/ControlsPanel/ControlsMargin/ControlsHBox/OrientationCheckButton")
	orientation_button.button_pressed = false
	orientation_button.toggled.emit(false)
	assert_eq(orientation_button.text, "Landscape")
