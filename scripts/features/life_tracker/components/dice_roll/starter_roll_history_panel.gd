extends PanelContainer

const STARTER_DIE_SCENE: PackedScene = preload("res://scenes/features/life_tracker/components/dice_roll/starter_die_view.tscn")

@onready var history_dice_container: HBoxContainer = $HistoryMargin/HistoryContent/HistoryDiceContainer

func clear_history() -> void:
	_clear_children(history_dice_container)
	visible = false

func show_history(candidate_players: Array[Dictionary], round_results: Dictionary) -> void:
	_clear_children(history_dice_container)
	visible = true

	for player_data: Dictionary in candidate_players:
		var player_index: int = int(player_data.get("player_index", -1))
		var key: String = str(player_index)
		var die_view: Control = STARTER_DIE_SCENE.instantiate()
		history_dice_container.add_child(die_view)
		var player_name: String = str(player_data.get("player_name", "Player"))
		var player_color: Color = player_data.get("player_color", Color(0.2, 0.2, 0.2, 1.0))
		var roll_value: int = int(round_results.get(key, 1))
		die_view.call("setup", player_index, player_name, player_color, true)
		die_view.call("set_roll_value", roll_value)

	_update_panel_width(candidate_players.size())

func get_history_dice_count() -> int:
	return history_dice_container.get_child_count()

func _update_panel_width(dice_count: int) -> void:
	var compact_die_width: float = 129.0
	var dice_spacing: float = 9.0
	var panel_padding: float = 24.0
	var min_width: float = 330.0
	var count: int = maxi(dice_count, 1)
	var content_width: float = compact_die_width * float(count) + dice_spacing * float(maxi(count - 1, 0))
	custom_minimum_size.x = max(min_width, content_width + panel_padding)
	size.x = custom_minimum_size.x

func _clear_children(node: Node) -> void:
	for child: Node in node.get_children():
		node.remove_child(child)
		child.queue_free()
