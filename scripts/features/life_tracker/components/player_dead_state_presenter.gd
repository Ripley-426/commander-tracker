extends Node
class_name PlayerDeadStatePresenter

func apply_state(panel: Panel, base_panel_color: Color, is_dead: bool, top_life_button: Button, bottom_life_button: Button, commander_damage_component: Control) -> void:
	top_life_button.call("set_interactable", not is_dead)
	bottom_life_button.call("set_interactable", not is_dead)
	commander_damage_component.call("set_interactable", not is_dead)

	if is_dead:
		_apply_panel_color(panel, _build_dead_color(base_panel_color))
		return
	_apply_panel_color(panel, base_panel_color)

func _build_dead_color(source_color: Color) -> Color:
	var desaturated_s: float = clampf(source_color.s * 0.35, 0.0, 1.0)
	var adjusted_v: float = clampf(source_color.v * 0.9, 0.0, 1.0)
	return Color.from_hsv(source_color.h, desaturated_s, adjusted_v, source_color.a)

func _apply_panel_color(panel: Panel, panel_color: Color) -> void:
	var panel_style: StyleBoxFlat = StyleBoxFlat.new()
	panel_style.bg_color = panel_color
	panel_style.corner_radius_top_left = 0
	panel_style.corner_radius_top_right = 0
	panel_style.corner_radius_bottom_right = 0
	panel_style.corner_radius_bottom_left = 0
	panel.add_theme_stylebox_override("panel", panel_style)
