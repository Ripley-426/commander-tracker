extends Control

const PERSISTENCE_STORE_SCRIPT: GDScript = preload("res://scripts/data/persistence_store.gd")

@onready var continue_button: Button = $CenterContainer/MarginContainer/VBoxContainer/ContinueButton
@onready var new_game_button: Button = $CenterContainer/MarginContainer/VBoxContainer/NewGameButton
@onready var layout_debug_button: Button = $CenterContainer/MarginContainer/VBoxContainer/LayoutDebugButton
@onready var exit_button: Button = $CenterContainer/MarginContainer/VBoxContainer/ExitButton

var store: RefCounted = PERSISTENCE_STORE_SCRIPT.new()
var on_open_life_tracker: Callable = Callable()
var on_open_game_config: Callable = Callable()
var on_open_layout_debug: Callable = Callable()

func _ready() -> void:
	continue_button.pressed.connect(_on_continue_pressed)
	new_game_button.pressed.connect(_on_new_game_pressed)
	layout_debug_button.pressed.connect(_on_layout_debug_pressed)
	exit_button.pressed.connect(_on_exit_pressed)

	if OS.has_feature("mobile"):
		exit_button.visible = false

	_refresh_buttons()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_IN:
		_refresh_buttons()

func _refresh_buttons() -> void:
	var has_game: bool = store.has_active_game()
	continue_button.visible = has_game
	continue_button.disabled = not has_game

func _on_continue_pressed() -> void:
	if on_open_life_tracker.is_valid():
		on_open_life_tracker.call()
		return
	get_tree().change_scene_to_file("res://scenes/features/life_tracker/life_tracker.tscn")

func _on_new_game_pressed() -> void:
	if on_open_game_config.is_valid():
		on_open_game_config.call()
		return
	get_tree().change_scene_to_file("res://scenes/features/game_config/game_config.tscn")

func _on_layout_debug_pressed() -> void:
	if on_open_layout_debug.is_valid():
		on_open_layout_debug.call()
		return
	get_tree().change_scene_to_file("res://scenes/features/layout_debug/layout_debug.tscn")

func _on_exit_pressed() -> void:
	get_tree().quit()
