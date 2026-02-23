extends Panel

signal life_delta_requested(player_index: int, delta: int)
signal commander_delta_requested(target_player_index: int, source_player_index: int, delta: int)
signal dead_state_changed(player_index: int, is_dead: bool)

@onready var name_label: Label = $HeaderArea/NameLabel
@onready var life_label: Label = $MiddleArea/LifeLabel
@onready var delta_label: Label = $MiddleArea/DeltaLabel
@onready var top_hit_button: Button = $HitZones/TopHitButton
@onready var bottom_hit_button: Button = $HitZones/BottomHitButton
@onready var dead_button: Button = $DeadButton
@onready var commander_damage_component: Control = $CommanderDamageContainer
@onready var dead_state_presenter: Node = $DeadStatePresenter
@onready var delta_reset_timer: Timer = $DeltaResetTimer

var player_index: int = -1
var is_rotated_180: bool = false
var pending_delta: int = 0
var base_panel_color: Color = Color(0.0, 0.0, 0.0, 1.0)
var is_dead: bool = false

func _ready() -> void:
	top_hit_button.connect("delta_requested", Callable(self, "_on_life_delta_requested"))
	bottom_hit_button.connect("delta_requested", Callable(self, "_on_life_delta_requested"))
	dead_button.connect("dead_toggled", Callable(self, "_on_dead_toggled"))
	commander_damage_component.connect("delta_requested", Callable(self, "_on_commander_row_delta_requested"))
	delta_reset_timer.timeout.connect(_on_delta_reset_timeout)
	_apply_hit_zone_styles(top_hit_button)
	_apply_hit_zone_styles(bottom_hit_button)
	_refresh_delta_label()
	_refresh_dynamic_text_size()

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		if life_label == null or commander_damage_component == null:
			return
		_refresh_dynamic_text_size()
		commander_damage_component.call("layout_for_panel_size", size)

func setup(index: int, player_name: String, life: int, panel_color: Color, rotate_180: bool = false, commander_rows: Array[Dictionary] = []) -> void:
	player_index = index
	is_rotated_180 = rotate_180
	base_panel_color = panel_color
	is_dead = false
	name_label.text = player_name
	life_label.text = str(life)
	_apply_rotation(rotate_180)
	commander_damage_component.call("setup_rows", commander_rows, is_dead)
	dead_button.call("set_dead", is_dead, false)
	set_dead(is_dead, false)
	commander_damage_component.call("layout_for_panel_size", size)

func set_life(life: int) -> void:
	life_label.text = str(life)

func add_life_delta_feedback(delta: int) -> void:
	if delta == 0:
		return
	_register_delta(delta)

func set_commander_damage(source_player_index: int, damage: int) -> void:
	commander_damage_component.call("set_damage", source_player_index, damage)

func _on_life_delta_requested(delta: int) -> void:
	_register_delta(delta)
	life_delta_requested.emit(player_index, delta)

func _register_delta(delta: int) -> void:
	pending_delta += delta
	_refresh_delta_label()
	delta_reset_timer.start()

func _refresh_delta_label() -> void:
	if pending_delta == 0:
		delta_label.visible = false
		delta_label.text = "+0"
		return
	delta_label.visible = true
	delta_label.text = "%+d" % pending_delta

func _on_delta_reset_timeout() -> void:
	pending_delta = 0
	_refresh_delta_label()

func _on_commander_row_delta_requested(source_player_index: int, delta: int) -> void:
	if delta == 0:
		return
	commander_delta_requested.emit(player_index, source_player_index, delta)

func _on_dead_toggled(next_dead: bool) -> void:
	set_dead(next_dead, true)

func set_dead(next_dead: bool, should_emit_signal: bool = true) -> void:
	is_dead = next_dead
	dead_button.call("set_dead", next_dead, false)
	dead_state_presenter.call("apply_state", self, base_panel_color, is_dead, top_hit_button, bottom_hit_button, commander_damage_component)
	if should_emit_signal:
		dead_state_changed.emit(player_index, is_dead)

func _apply_hit_zone_styles(hit_button: Button) -> void:
	var normal_style: StyleBoxFlat = StyleBoxFlat.new()
	normal_style.bg_color = Color(1.0, 1.0, 1.0, 0.0)
	normal_style.shadow_color = Color(0.0, 0.0, 0.0, 0.0)
	normal_style.shadow_size = 0

	var hover_style: StyleBoxFlat = normal_style.duplicate() as StyleBoxFlat
	hover_style.bg_color = Color(1.0, 1.0, 1.0, 0.06)

	var pressed_style: StyleBoxFlat = normal_style.duplicate() as StyleBoxFlat
	pressed_style.bg_color = Color(1.0, 1.0, 1.0, 0.24)
	pressed_style.shadow_color = Color(0.0, 0.0, 0.0, 0.34)
	pressed_style.shadow_size = 10

	var disabled_style: StyleBoxFlat = normal_style.duplicate() as StyleBoxFlat
	var focus_style: StyleBoxFlat = hover_style.duplicate() as StyleBoxFlat

	hit_button.add_theme_stylebox_override("normal", normal_style)
	hit_button.add_theme_stylebox_override("hover", hover_style)
	hit_button.add_theme_stylebox_override("pressed", pressed_style)
	hit_button.add_theme_stylebox_override("disabled", disabled_style)
	hit_button.add_theme_stylebox_override("focus", focus_style)

func _apply_rotation(rotate_180: bool) -> void:
	rotation_degrees = 180.0 if rotate_180 else 0.0
	call_deferred("_update_pivot_for_rotation")

func _update_pivot_for_rotation() -> void:
	pivot_offset = size * 0.5

func _refresh_dynamic_text_size() -> void:
	if life_label == null:
		return
	var computed_size: int = int(round(size.y * 0.68))
	var clamped_size: int = clampi(computed_size, 84, 320)
	life_label.add_theme_font_size_override("font_size", clamped_size)
