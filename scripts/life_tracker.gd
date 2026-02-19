extends Control

const PLAYER_PANEL_SCENE: PackedScene = preload("res://scenes/components/player_panel.tscn")
const PLAYER_COLORS: Array[Color] = [
	Color(0.86, 0.26, 0.26, 1.0),
	Color(0.22, 0.58, 0.92, 1.0),
	Color(0.20, 0.72, 0.40, 1.0),
	Color(0.95, 0.62, 0.18, 1.0),
	Color(0.55, 0.42, 0.84, 1.0),
	Color(0.92, 0.33, 0.66, 1.0)
]

@onready var board_container: Control = $VBoxContainer/BoardContainer
@onready var menu_button: Button = $VBoxContainer/TopBar/MenuButton
@onready var new_game_button: Button = $VBoxContainer/TopBar/NewGameButton

var store: Object = PersistenceStore.new()
var session_service: Object = null
var game_state: Dictionary = {}
var on_open_main_menu: Callable = Callable()
var on_open_game_config: Callable = Callable()

func _ready() -> void:
	menu_button.pressed.connect(_on_menu_pressed)
	new_game_button.pressed.connect(_on_new_game_pressed)

	if session_service == null:
		session_service = _create_session_service(store)

	game_state = session_service.load_active_game()
	if game_state.is_empty():
		_open_main_menu()
		return

	_render_state()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED \
	or what == NOTIFICATION_WM_CLOSE_REQUEST \
	or what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		_commit_state()

func _render_state() -> void:
	_clear_children(board_container)

	var players: Array = game_state.get("players", [])
	var settings_value: Variant = game_state.get("settings", {})
	var settings: Dictionary = settings_value if typeof(settings_value) == TYPE_DICTIONARY else {}
	var layout_id: String = str(settings.get("layout_id", ""))
	var slots: Array[Dictionary] = _get_layout_slots(layout_id, players.size())

	for i: int in range(players.size()):
		var player: Dictionary = players[i]
		var player_name: String = str(player.get("name", "Player"))
		var life: int = int(player.get("life", 0))
		var panel_color: Color = PLAYER_COLORS[i % PLAYER_COLORS.size()]
		var slot: Dictionary = slots[i] if i < slots.size() else {"x": 0.05, "y": 0.05, "w": 0.40, "h": 0.40}
		var should_rotate: bool = i < 2
		_add_player_panel(i, player_name, life, panel_color, slot, should_rotate)

func _add_player_panel(player_index: int, player_name: String, life: int, panel_color: Color, slot: Dictionary, should_rotate: bool) -> void:
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

	panel.setup(player_index, player_name, life, panel_color, should_rotate)
	panel.life_delta_requested.connect(_on_life_delta_pressed)

func _on_life_delta_pressed(player_index: int, delta: int) -> void:
	var changed: bool = session_service.apply_life_delta(game_state, player_index, delta)
	if changed:
		_commit_and_render()

func _commit_and_render() -> void:
	_commit_state()
	_render_state()

func _commit_state() -> void:
	if game_state.is_empty():
		return
	session_service.save_state(game_state)

func _on_menu_pressed() -> void:
	_commit_state()
	_open_main_menu()

func _on_new_game_pressed() -> void:
	_commit_state()
	_open_game_config()

func _clear_children(node: Node) -> void:
	for child in node.get_children():
		child.queue_free()

func _open_main_menu() -> void:
	if on_open_main_menu.is_valid():
		on_open_main_menu.call()
		return
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func _open_game_config() -> void:
	if on_open_game_config.is_valid():
		on_open_game_config.call()
		return
	get_tree().change_scene_to_file("res://scenes/game_config.tscn")

func _create_session_service(p_store: Object) -> Object:
	var service_script: GDScript = load("res://scripts/game_session_service.gd")
	return service_script.new(p_store)

func _get_layout_slots(layout_id: String, player_count: int) -> Array[Dictionary]:
	var layout_script: GDScript = load("res://scripts/player_layout_service.gd")
	return layout_script.get_slots(layout_id, player_count)
