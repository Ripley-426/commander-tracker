extends GutTest

func _create_die_view() -> Control:
	var scene: PackedScene = load("res://scenes/features/life_tracker/components/dice_roll/starter_die_view.tscn")
	var die_view: Control = scene.instantiate()
	add_child_autofree(die_view)
	die_view.call("setup", 0, "Player 1", Color(0.86, 0.26, 0.26, 1.0), false)
	return die_view

func test_set_winner_animates_scale() -> void:
	var die_view: Control = _create_die_view()
	die_view.call("set_winner", true)
	await get_tree().create_timer(0.7).timeout
	assert_true(die_view.scale.x > 1.0)

func test_set_winner_false_resets_scale_to_default() -> void:
	var die_view: Control = _create_die_view()
	die_view.call("set_winner", true)
	die_view.call("set_winner", false)
	assert_eq(die_view.scale, Vector2.ONE)

func test_die_view_pivot_offset_is_centered() -> void:
	var die_view: Control = _create_die_view()
	await get_tree().process_frame
	assert_eq(die_view.pivot_offset, die_view.size * 0.5)
