extends SceneTree

@warning_ignore("unsafe_method_access")
func _init() -> void:
	ProjectSettings.set("debug/gdscript/warnings/exclude_addons", false)

	var max_iter: int = 20
	var iter: int = 0
	var loader: Object = load("res://addons/gut/gut_loader.gd")

	while Engine.get_main_loop() == null and iter < max_iter:
		await create_timer(0.01).timeout
		iter += 1

	if Engine.get_main_loop() == null:
		push_error("Main loop did not start in time.")
		quit(0)
		return

	var cli: Node = load("res://addons/gut/cli/gut_cli.gd").new()
	get_root().add_child(cli)
	loader.restore_ignore_addons()
	cli.main()
