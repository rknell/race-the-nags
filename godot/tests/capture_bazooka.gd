extends SceneTree

func _initialize() -> void:
	call_deferred("capture")

func capture() -> void:
	var main = load("res://scenes/main.tscn").instantiate()
	main.settings_path = "user://bazooka-capture.cfg"
	main.save_path = "user://bazooka-capture-save.json"
	main.history_path = "user://bazooka-capture-history.json"
	root.add_child(main)
	main.sound_on = false
	main.model.new_game(["MEGHANN"], 1245)
	main.model.played_races = 3
	main.build_game()
	main.primary_action()
	main.model.advance(4.0)
	main.set_process(false)
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://../docs/bazooka-crate.png")
	main.fire_bazooka()
	main.track.blast_age = 0.45
	main.track.set_process(false)
	main.track.queue_redraw()
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://../docs/bazooka-blast.png")
	for path in [main.settings_path, main.save_path, main.history_path]:
		DirAccess.remove_absolute(path)
	main.queue_free()
	await process_frame
	quit()
