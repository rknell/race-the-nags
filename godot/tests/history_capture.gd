extends SceneTree
func _initialize() -> void:
	call_deferred("capture")
func shot(file_name: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://../docs/" + file_name)
func capture() -> void:
	var main = load("res://scenes/main.tscn").instantiate()
	main.settings_path = "user://history-capture-settings.cfg"
	main.history_path = "user://history-capture-records.json"
	main.save_path = "user://history-capture-save.json"
	root.add_child(main)
	main.sound_on = false
	main.mode_choice.select(1)
	main.update_mode_description()
	main.update_history_button()
	await shot("history-home.png")
	main.show_history_simulation()
	await shot("history-options.png")
	await main.run_history_simulation()
	await shot("history-ready.png")
	for path in [main.settings_path, main.history_path, main.save_path]:
		DirAccess.remove_absolute(path)
	main.queue_free()
	await process_frame
	quit()
