extends Button

signal dead_toggled(is_dead: bool)

var is_dead: bool = false

func _ready() -> void:
	pressed.connect(_on_pressed)

func set_dead(next_dead: bool, should_emit_signal: bool = false) -> void:
	if is_dead == next_dead:
		return
	is_dead = next_dead
	if should_emit_signal:
		dead_toggled.emit(is_dead)

func _on_pressed() -> void:
	set_dead(not is_dead, true)
