extends Control

const GAME_STATE_SCRIPT: GDScript = preload("res://scripts/domain/game_state.gd")
const PLAYER_LAYOUT_SERVICE_SCRIPT: GDScript = preload("res://scripts/domain/player_layout_service.gd")
const PLAYER_PANEL_SCENE: PackedScene = preload("res://scenes/features/life_tracker/components/player_panel/player_panel.tscn")
const PLAYER_COLORS: Array[Color] = [
	Color(0.86, 0.26, 0.26, 1.0),
	Color(0.22, 0.58, 0.92, 1.0),
	Color(0.20, 0.72, 0.40, 1.0),
	Color(0.95, 0.62, 0.18, 1.0),
	Color(0.55, 0.42, 0.84, 1.0),
	Color(0.92, 0.33, 0.66, 1.0)
]

@onready var back_button: Button = $RootMargin/RootVBox/ControlsPanel/ControlsMargin/ControlsHBox/BackButton
@onready var decrease_button: Button = $RootMargin/RootVBox/ControlsPanel/ControlsMargin/ControlsHBox/DecreaseButton
@onready var increase_button: Button = $RootMargin/RootVBox/ControlsPanel/ControlsMargin/ControlsHBox/IncreaseButton
@onready var player_count_label: Label = $RootMargin/RootVBox/ControlsPanel/ControlsMargin/ControlsHBox/PlayerCountValueLabel
@onready var layout_option_button: OptionButton = $RootMargin/RootVBox/ControlsPanel/ControlsMargin/ControlsHBox/LayoutOptionButton
@onready var orientation_check_button: CheckButton = $RootMargin/RootVBox/ControlsPanel/ControlsMargin/ControlsHBox/OrientationCheckButton
@onready var board_container: Control = $RootMargin/RootVBox/BoardPanel/BoardContainer

var player_count: int = 4
var current_layouts: Array[Dictionary] = []
var on_open_main_menu: Callable = Callable()

func _ready() -> void:
	back_button.pressed.connect(_on_back_pressed)
	decrease_button.pressed.connect(_on_decrease_pressed)
	increase_button.pressed.connect(_on_increase_pressed)
	layout_option_button.item_selected.connect(_on_layout_selected)
	orientation_check_button.toggled.connect(_on_orientation_toggled)
	_refresh_layout_presets()
	_render_preview()

func _notification(what: int) -> void:
	if what != NOTIFICATION_RESIZED:
		return
	if board_container == null:
		return
	_render_preview()

func _on_back_pressed() -> void:
	if on_open_main_menu.is_valid():
		on_open_main_menu.call()
		return
	get_tree().change_scene_to_file("res://scenes/features/main_menu/main_menu.tscn")

func _on_decrease_pressed() -> void:
	player_count = maxi(player_count - 1, 2)
	_refresh_layout_presets()
	_render_preview()

func _on_increase_pressed() -> void:
	player_count = mini(player_count + 1, 6)
	_refresh_layout_presets()
	_render_preview()

func _on_layout_selected(_index: int) -> void:
	_render_preview()

func _on_orientation_toggled(button_pressed: bool) -> void:
	orientation_check_button.text = "Portrait" if button_pressed else "Landscape"
	_render_preview()

func _refresh_layout_presets() -> void:
	player_count_label.text = str(player_count)
	current_layouts = GAME_STATE_SCRIPT.get_layout_presets(player_count)
	layout_option_button.clear()
	for i: int in range(current_layouts.size()):
		var layout: Dictionary = current_layouts[i]
		layout_option_button.add_item(str(layout.get("name", "")), i)
	if current_layouts.size() > 0:
		layout_option_button.selected = 0

func _render_preview() -> void:
	_clear_children(board_container)
	if current_layouts.is_empty():
		return
	var selected_index: int = mini(layout_option_button.selected, current_layouts.size() - 1)
	var layout_id: String = str(current_layouts[selected_index].get("id", ""))
	var is_portrait: bool = orientation_check_button.button_pressed
	var slots: Array[Dictionary] = PLAYER_LAYOUT_SERVICE_SCRIPT.get_slots(layout_id, player_count, is_portrait)
	for i: int in range(slots.size()):
		var slot: Dictionary = slots[i]
		var panel: Control = PLAYER_PANEL_SCENE.instantiate()
		board_container.add_child(panel)
		panel.anchor_left = float(slot.get("x", 0.0))
		panel.anchor_top = float(slot.get("y", 0.0))
		panel.anchor_right = panel.anchor_left + float(slot.get("w", 0.5))
		panel.anchor_bottom = panel.anchor_top + float(slot.get("h", 0.5))
		panel.offset_left = 0.0
		panel.offset_top = 0.0
		panel.offset_right = 0.0
		panel.offset_bottom = 0.0
		var row_data: Array[Dictionary] = _build_rows_for_target(i, player_count)
		panel.setup(i, "Player %d" % (i + 1), 40, PLAYER_COLORS[i % PLAYER_COLORS.size()], false, row_data)
		panel.call("set_rotation_degrees_custom", float(slot.get("rotation_degrees", 0.0)))

func _build_rows_for_target(target_index: int, count: int) -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	for source_index: int in range(count):
		if source_index == target_index:
			continue
		rows.append({
			"source_index": source_index,
			"source_name": "Player %d" % (source_index + 1),
			"source_color": PLAYER_COLORS[source_index % PLAYER_COLORS.size()],
			"damage": 0
		})
	return rows

func _clear_children(node: Node) -> void:
	for child: Node in node.get_children():
		node.remove_child(child)
		child.queue_free()
