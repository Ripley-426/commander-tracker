extends Control

@onready var continue_button: Button = $CenterContainer/VBoxContainer/ContinueButton
@onready var new_game_button: Button = $CenterContainer/VBoxContainer/NewGameButton
@onready var exit_button: Button = $CenterContainer/VBoxContainer/ExitButton

var store: Object = PersistenceStore.new()
var on_open_life_tracker: Callable = Callable()
var on_open_game_config: Callable = Callable()

func _ready() -> void:
	continue_button.pressed.connect(_on_continue_pressed)
	new_game_button.pressed.connect(_on_new_game_pressed)
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
	get_tree().change_scene_to_file("res://scenes/life_tracker.tscn")

func _on_new_game_pressed() -> void:
	if on_open_game_config.is_valid():
		on_open_game_config.call()
		return
	get_tree().change_scene_to_file("res://scenes/game_config.tscn")

func _on_exit_pressed() -> void:
	get_tree().quit()
