extends SceneTree

func _initialize() -> void:
	call_deferred("capture")

func screenshot(path: String) -> void:
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://../docs/" + path)

func capture() -> void:
	var main = load("res://scenes/main.tscn").instantiate()
	main.settings_path = "user://graphics-capture.cfg"
	main.history_path = "user://graphics-capture-history.json"
	main.save_path = "user://graphics-capture-save.json"
	root.add_child(main)
	main.sound_on = false
	main.set_process(false)
	for mode in [0, 1]:
		main.show_title()
		main.set_graphics_mode(mode)
		var label: String = "classic" if mode == 0 else "remastered"
		await screenshot(label + "-title-screen.png")
		main.model.new_game(["PLAYER ONE"], 1245)
		main.build_game()
		main.primary_action()
		main.model.advance(5)
		await screenshot(label + "-race-screen.png")
		for horse in main.model.field:
			horse.fallen = true
		await screenshot(label + "-fallen-screen.png")
	DirAccess.remove_absolute(main.settings_path)
	main.queue_free()
	await process_frame
	quit()
