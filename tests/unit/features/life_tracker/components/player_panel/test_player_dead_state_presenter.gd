extends GutTest

class FakeCommanderDamageComponent extends Control:
	var is_interactable: bool = true

	func set_interactable(enabled: bool) -> void:
		is_interactable = enabled

func _create_presenter() -> Node:
	var scene: PackedScene = load("res://scenes/features/life_tracker/components/player_panel/player_dead_state_presenter.tscn")
	var presenter: Node = scene.instantiate()
	add_child_autofree(presenter)
	return presenter

func _create_hold_button() -> Button:
	var scene: PackedScene = load("res://scenes/features/life_tracker/components/player_panel/hold_repeat_button.tscn")
	var button: Button = scene.instantiate()
	add_child_autofree(button)
	return button

func _create_panel() -> Panel:
	var panel: Panel = Panel.new()
	add_child_autofree(panel)
	return panel

func _create_commander_component() -> FakeCommanderDamageComponent:
	var component: FakeCommanderDamageComponent = FakeCommanderDamageComponent.new()
	add_child_autofree(component)
	return component

func test_dead_state_disables_top_life_button() -> void:
	var presenter: Node = _create_presenter()
	var panel: Panel = _create_panel()
	var top_button: Button = _create_hold_button()
	var bottom_button: Button = _create_hold_button()
	var commander_component: FakeCommanderDamageComponent = _create_commander_component()

	presenter.call("apply_state", panel, Color(0.8, 0.2, 0.2, 1.0), true, top_button, bottom_button, commander_component)
	assert_true(top_button.disabled)

func test_dead_state_disables_bottom_life_button() -> void:
	var presenter: Node = _create_presenter()
	var panel: Panel = _create_panel()
	var top_button: Button = _create_hold_button()
	var bottom_button: Button = _create_hold_button()
	var commander_component: FakeCommanderDamageComponent = _create_commander_component()

	presenter.call("apply_state", panel, Color(0.8, 0.2, 0.2, 1.0), true, top_button, bottom_button, commander_component)
	assert_true(bottom_button.disabled)

func test_dead_state_disables_commander_component() -> void:
	var presenter: Node = _create_presenter()
	var panel: Panel = _create_panel()
	var top_button: Button = _create_hold_button()
	var bottom_button: Button = _create_hold_button()
	var commander_component: FakeCommanderDamageComponent = _create_commander_component()

	presenter.call("apply_state", panel, Color(0.8, 0.2, 0.2, 1.0), true, top_button, bottom_button, commander_component)
	assert_false(commander_component.is_interactable)

func test_dead_state_applies_desaturated_color() -> void:
	var presenter: Node = _create_presenter()
	var panel: Panel = _create_panel()
	var top_button: Button = _create_hold_button()
	var bottom_button: Button = _create_hold_button()
	var commander_component: FakeCommanderDamageComponent = _create_commander_component()
	var base_color: Color = Color(0.86, 0.26, 0.26, 1.0)

	presenter.call("apply_state", panel, base_color, true, top_button, bottom_button, commander_component)
	var applied_style: StyleBoxFlat = panel.get_theme_stylebox("panel") as StyleBoxFlat
	assert_true(applied_style.bg_color.s < base_color.s)

func test_alive_state_restores_base_color() -> void:
	var presenter: Node = _create_presenter()
	var panel: Panel = _create_panel()
	var top_button: Button = _create_hold_button()
	var bottom_button: Button = _create_hold_button()
	var commander_component: FakeCommanderDamageComponent = _create_commander_component()
	var base_color: Color = Color(0.86, 0.26, 0.26, 1.0)

	presenter.call("apply_state", panel, base_color, true, top_button, bottom_button, commander_component)
	presenter.call("apply_state", panel, base_color, false, top_button, bottom_button, commander_component)
	var applied_style: StyleBoxFlat = panel.get_theme_stylebox("panel") as StyleBoxFlat
	assert_eq(applied_style.bg_color, base_color)

func test_alive_state_enables_top_life_button() -> void:
	var presenter: Node = _create_presenter()
	var panel: Panel = _create_panel()
	var top_button: Button = _create_hold_button()
	var bottom_button: Button = _create_hold_button()
	var commander_component: FakeCommanderDamageComponent = _create_commander_component()

	presenter.call("apply_state", panel, Color(0.8, 0.2, 0.2, 1.0), true, top_button, bottom_button, commander_component)
	presenter.call("apply_state", panel, Color(0.8, 0.2, 0.2, 1.0), false, top_button, bottom_button, commander_component)
	assert_false(top_button.disabled)

