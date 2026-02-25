extends Control

const STARTER_DIE_SCENE: PackedScene = preload("res://scenes/features/life_tracker/components/dice_roll/starter_die_view.tscn")
const STARTER_ROLL_ENGINE_SCRIPT: GDScript = preload("res://scripts/features/life_tracker/components/dice_roll/starter_roll_engine.gd")
const HISTORY_PANEL_MARGIN: float = 14.0

signal closed()
signal winner_decided(player_index: int)

@onready var dim_layer: ColorRect = $DimLayer
@onready var main_panel: PanelContainer = $MainPanel
@onready var status_label: Label = $MainPanel/PanelMargin/MainContent/StatusLabel
@onready var center_dice_container: HBoxContainer = $MainPanel/PanelMargin/MainContent/CenterDiceContainer
@onready var history_panel: PanelContainer = $HistoryPanel
@onready var round_delay_timer: Timer = $RoundDelayTimer
@onready var roll_tick_timer: Timer = $RollTickTimer

var candidate_players: Array[Dictionary] = []
var current_dice_by_player: Dictionary = {}
var current_round_results: Dictionary = {}
var winner_player_index: int = -1
var winner_player_name: String = ""
var can_close: bool = false
var is_rolling: bool = false
var should_animate_round: bool = true
var roll_tick_count: int = 0
var latest_round_outcome: Dictionary = {}
var roll_engine: RefCounted = STARTER_ROLL_ENGINE_SCRIPT.new()

func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP
	gui_input.connect(_on_overlay_input)
	dim_layer.gui_input.connect(_on_overlay_input)
	main_panel.gui_input.connect(_on_overlay_input)
	round_delay_timer.timeout.connect(_on_round_delay_timeout)
	roll_tick_timer.timeout.connect(_on_roll_tick_timeout)
	call_deferred("_apply_portrait_rotation")

func _notification(what: int) -> void:
	if what != NOTIFICATION_RESIZED:
		return
	if not is_node_ready():
		return
	_apply_portrait_rotation()

func start_roll_for_players(players: Array[Dictionary], animate_round: bool = true) -> void:
	candidate_players = players.duplicate(true)
	should_animate_round = animate_round
	winner_player_index = -1
	winner_player_name = ""
	can_close = false
	is_rolling = false
	roll_tick_count = 0
	current_round_results.clear()
	history_panel.call("clear_history")
	visible = true
	dim_layer.mouse_filter = Control.MOUSE_FILTER_STOP

	if candidate_players.size() <= 0:
		status_label.text = "No eligible players."
		can_close = true
		return
	_start_round()

func set_forced_roll_values(values: Array[int]) -> void:
	roll_engine.call("set_forced_roll_values", values)

func request_close() -> bool:
	if not can_close:
		return false
	visible = false
	closed.emit()
	return true

func get_winner_player_index() -> int:
	return winner_player_index

func get_history_dice_count() -> int:
	return int(history_panel.call("get_history_dice_count"))

func get_current_candidate_count() -> int:
	return candidate_players.size()

func is_waiting_for_close() -> bool:
	return can_close and visible

func _gui_input(event: InputEvent) -> void:
	_on_overlay_input(event)

func _on_overlay_input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventMouseButton:
		var mouse_event: InputEventMouseButton = event
		if mouse_event.pressed:
			request_close()
			accept_event()
	elif event is InputEventScreenTouch:
		var touch_event: InputEventScreenTouch = event
		if touch_event.pressed:
			request_close()
			accept_event()

func _start_round() -> void:
	if candidate_players.size() <= 0:
		status_label.text = "No eligible players."
		can_close = true
		return

	_clear_children(center_dice_container)
	current_dice_by_player.clear()
	current_round_results.clear()

	for player_data: Dictionary in candidate_players:
		var die_view: Control = STARTER_DIE_SCENE.instantiate()
		center_dice_container.add_child(die_view)
		var player_index: int = int(player_data.get("player_index", -1))
		var player_name: String = str(player_data.get("player_name", "Player"))
		var player_color: Color = player_data.get("player_color", Color(0.2, 0.2, 0.2, 1.0))
		die_view.call("setup", player_index, player_name, player_color, false)
		current_dice_by_player[str(player_index)] = die_view

	status_label.text = "Rolling..."
	is_rolling = true
	roll_tick_count = 0

	if should_animate_round:
		roll_tick_timer.start()
		return

	latest_round_outcome = _roll_once_for_all_candidates()
	_finish_current_round()

func _on_roll_tick_timeout() -> void:
	if not is_rolling:
		return
	latest_round_outcome = _roll_once_for_all_candidates()
	roll_tick_count += 1
	if roll_tick_count < 12:
		return
	roll_tick_timer.stop()
	_finish_current_round()

func _roll_once_for_all_candidates() -> Dictionary:
	var outcome: Dictionary = roll_engine.call("roll_round", candidate_players)
	var round_results_value: Variant = outcome.get("round_results", {})
	current_round_results = round_results_value if typeof(round_results_value) == TYPE_DICTIONARY else {}
	for key: String in current_round_results.keys():
		if not current_dice_by_player.has(key):
			continue
		var die_view: Control = current_dice_by_player[key]
		die_view.call("set_roll_value", int(current_round_results.get(key, 1)))
	return outcome

func _finish_current_round() -> void:
	is_rolling = false
	if current_round_results.size() <= 0:
		status_label.text = "No roll results."
		can_close = true
		return

	var highest_roll: int = int(latest_round_outcome.get("highest_roll", 0))
	var tied_players_value: Variant = latest_round_outcome.get("tied_players", [])
	var tied_players: Array[Dictionary] = tied_players_value if typeof(tied_players_value) == TYPE_ARRAY else []
	var winner_index: int = int(latest_round_outcome.get("winner_player_index", -1))
	if winner_index >= 0:
		winner_player_index = winner_index
		for candidate: Dictionary in candidate_players:
			if int(candidate.get("player_index", -1)) != winner_player_index:
				continue
			winner_player_name = str(candidate.get("player_name", "Player"))
			break
		var winner_key: String = str(winner_player_index)
		if current_dice_by_player.has(winner_key):
			var winner_die: Control = current_dice_by_player[winner_key]
			winner_die.call("set_winner", true)
		winner_decided.emit(winner_player_index)
		status_label.text = "%s starts." % winner_player_name
		can_close = true
		return

	_copy_current_round_to_history()
	candidate_players = tied_players
	status_label.text = "Tie at %d. Rolling tied players..." % highest_roll
	round_delay_timer.start()

func _copy_current_round_to_history() -> void:
	history_panel.call("show_history", candidate_players, current_round_results)
	_apply_portrait_rotation()

func _on_round_delay_timeout() -> void:
	_start_round()

func _clear_children(node: Node) -> void:
	for child: Node in node.get_children():
		node.remove_child(child)
		child.queue_free()

func _apply_portrait_rotation() -> void:
	if main_panel == null or history_panel == null:
		return
	main_panel.rotation_degrees = -90.0
	main_panel.pivot_offset = main_panel.size * 0.5
	history_panel.rotation_degrees = -90.0
	history_panel.pivot_offset = history_panel.size * 0.5
	_position_history_panel_for_view()

func _position_history_panel_for_view() -> void:
	var panel_size: Vector2 = history_panel.size
	if panel_size.is_equal_approx(Vector2.ZERO):
		panel_size = history_panel.custom_minimum_size

	var rotated_size: Vector2 = Vector2(panel_size.y, panel_size.x)
	var target_top_left: Vector2 = Vector2(HISTORY_PANEL_MARGIN, HISTORY_PANEL_MARGIN)
	if size.y >= size.x:
		var bottom_y: float = size.y - HISTORY_PANEL_MARGIN - rotated_size.y
		target_top_left.y = max(HISTORY_PANEL_MARGIN, bottom_y)

	var target_center: Vector2 = target_top_left + (rotated_size * 0.5)
	history_panel.position = target_center - (panel_size * 0.5)
