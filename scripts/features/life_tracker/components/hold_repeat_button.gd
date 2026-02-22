extends Button
class_name HoldRepeatButton

signal delta_requested(delta: int)

@export var tap_delta: int = 1
@export var hold_delta: int = 10
@export var hold_interval_seconds: float = 1.0

@onready var hold_repeat_timer: Timer = $HoldRepeatTimer

var hold_is_active: bool = false
var hold_emitted_repeat: bool = false

func _ready() -> void:
	button_down.connect(_on_button_down)
	button_up.connect(_on_button_up)
	hold_repeat_timer.timeout.connect(_on_hold_repeat_timeout)
	hold_repeat_timer.wait_time = hold_interval_seconds

func set_interactable(enabled: bool) -> void:
	disabled = not enabled
	if enabled:
		return
	_reset_hold_state()

func _on_button_down() -> void:
	if disabled:
		return
	hold_is_active = true
	hold_emitted_repeat = false
	hold_repeat_timer.start()

func _on_button_up() -> void:
	if not hold_is_active:
		return
	hold_repeat_timer.stop()
	var should_emit_tap: bool = not hold_emitted_repeat
	_reset_hold_state()
	if should_emit_tap:
		_emit_delta(tap_delta)

func _on_hold_repeat_timeout() -> void:
	if not hold_is_active:
		return
	hold_emitted_repeat = true
	_emit_delta(hold_delta if tap_delta >= 0 else -hold_delta)

func _emit_delta(delta: int) -> void:
	if delta == 0:
		return
	delta_requested.emit(delta)

func _reset_hold_state() -> void:
	hold_repeat_timer.stop()
	hold_is_active = false
	hold_emitted_repeat = false
