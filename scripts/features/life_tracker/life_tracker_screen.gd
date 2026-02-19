extends Control

const PLAYER_PANEL_SCENE: PackedScene = preload("res://scenes/features/life_tracker/components/player_panel.tscn")
const PLAYER_STATE_QUERIES: GDScript = preload("res://scripts/domain/player_state_queries.gd")
const PERSISTENCE_STORE_SCRIPT: GDScript = preload("res://scripts/data/persistence_store.gd")
const PLAYER_COLORS: Array[Color] = [
	Color(0.86, 0.26, 0.26, 1.0),
	Color(0.22, 0.58, 0.92, 1.0),
	Color(0.20, 0.72, 0.40, 1.0),
	Color(0.95, 0.62, 0.18, 1.0),
	Color(0.55, 0.42, 0.84, 1.0),
	Color(0.92, 0.33, 0.66, 1.0)
]

@onready var board_container: Control = $VBoxContainer/BoardContainer
@onready var tracker_menu_overlay: Control = $TrackerMenuOverlay

var store: RefCounted = PERSISTENCE_STORE_SCRIPT.new()
var session_service: RefCounted = null
var controller: RefCounted = null
var game_state: Dictionary = {}
var on_open_main_menu: Callable = Callable()
var on_open_game_config: Callable = Callable()

func _ready() -> void:
	tracker_menu_overlay.connect("main_menu_requested", Callable(self, "_on_menu_pressed"))
	tracker_menu_overlay.connect("new_game_requested", Callable(self, "_on_new_game_pressed"))

	if session_service == null:
		session_service = _create_session_service(store)
	if controller == null:
		controller = _create_controller(session_service)

	game_state = controller.load_state()
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
		var commander_rows: Array[Dictionary] = PLAYER_STATE_QUERIES.build_commander_rows_for_target(game_state, i, PLAYER_COLORS)
		_add_player_panel(i, player_name, life, panel_color, slot, should_rotate, commander_rows)

func _add_player_panel(player_index: int, player_name: String, life: int, panel_color: Color, slot: Dictionary, should_rotate: bool, commander_rows: Array[Dictionary]) -> void:
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

	panel.setup(player_index, player_name, life, panel_color, should_rotate, commander_rows)
	panel.life_delta_requested.connect(_on_life_delta_pressed)
	panel.commander_delta_requested.connect(_on_commander_delta_pressed)

func _on_life_delta_pressed(player_index: int, delta: int) -> void:
	var changed: bool = controller.apply_life_delta(player_index, delta)
	if changed:
		game_state = controller.get_state()
		_refresh_player_life(player_index)

func _refresh_player_life(player_index: int) -> void:
	if player_index < 0 or player_index >= board_container.get_child_count():
		return
	var panel_node: Node = board_container.get_child(player_index)
	if panel_node == null:
		return

	var players: Array = game_state.get("players", [])
	if player_index < 0 or player_index >= players.size():
		return
	var player_value: Variant = players[player_index]
	if typeof(player_value) != TYPE_DICTIONARY:
		return
	var player: Dictionary = player_value
	var life: int = int(player.get("life", 0))
	panel_node.call("set_life", life)

func _on_commander_delta_pressed(target_player_index: int, source_player_index: int, delta: int) -> void:
	var previous_life: int = PLAYER_STATE_QUERIES.get_player_life(game_state, target_player_index)
	var changed: bool = controller.apply_commander_delta_with_life_loss(source_player_index, target_player_index, delta)
	if not changed:
		return
	game_state = controller.get_state()
	var next_life: int = PLAYER_STATE_QUERIES.get_player_life(game_state, target_player_index)
	var life_delta: int = next_life - previous_life
	_refresh_player_commander_damage(target_player_index, source_player_index)
	_refresh_player_life(target_player_index)
	if life_delta != 0:
		_add_panel_life_feedback(target_player_index, life_delta)

func _refresh_player_commander_damage(target_player_index: int, source_player_index: int) -> void:
	if target_player_index < 0 or target_player_index >= board_container.get_child_count():
		return

	var panel_node: Node = board_container.get_child(target_player_index)
	if panel_node == null:
		return

	var damage: int = PLAYER_STATE_QUERIES.get_commander_damage(game_state, source_player_index, target_player_index)
	panel_node.call("set_commander_damage", source_player_index, max(damage, 0))

func _add_panel_life_feedback(player_index: int, delta: int) -> void:
	if player_index < 0 or player_index >= board_container.get_child_count():
		return
	var panel_node: Node = board_container.get_child(player_index)
	if panel_node == null:
		return
	panel_node.call("add_life_delta_feedback", delta)

func _commit_state() -> void:
	if game_state.is_empty():
		return
	controller.commit_state()

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
	get_tree().change_scene_to_file("res://scenes/features/main_menu/main_menu.tscn")

func _open_game_config() -> void:
	if on_open_game_config.is_valid():
		on_open_game_config.call()
		return
	get_tree().change_scene_to_file("res://scenes/features/game_config/game_config.tscn")

func _create_session_service(p_store: RefCounted) -> RefCounted:
	var service_script: GDScript = load("res://scripts/domain/game_session_service.gd")
	return service_script.new(p_store)

func _create_controller(p_session: RefCounted) -> RefCounted:
	var controller_script: GDScript = load("res://scripts/domain/life_tracker_controller.gd")
	return controller_script.new(p_session)

func _get_layout_slots(layout_id: String, player_count: int) -> Array[Dictionary]:
	var layout_script: GDScript = load("res://scripts/domain/player_layout_service.gd")
	return layout_script.get_slots(layout_id, player_count)
