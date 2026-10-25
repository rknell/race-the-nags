extends SceneTree
func _initialize() -> void:
	call_deferred("capture")
func capture() -> void:
	var main = load("res://scenes/main.tscn").instantiate()
	main.settings_path = "user://public-capture.cfg"
	main.history_path = "user://public-capture-records.json"
	main.save_path = "user://public-capture-save.json"
	root.add_child(main)
	main.names[0].text = "PLAYER ONE"
	main.set_graphics_mode(0)
	main.sound_on = false
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://../docs/title-screen.png")
	main.model.new_game(["PLAYER ONE", "PLAYER TWO", "PLAYER THREE", "PLAYER FOUR", "PLAYER FIVE", "PLAYER SIX"], 1245)
	main.build_game()
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://../docs/betting-screen.png")
	main.primary_action()
	main.model.advance(5.0)
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://../docs/race-screen.png")
	main.model.advance(200)
	main.update_game()
	main.show_results()
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://../docs/results-screen.png")
	main.queue_free()
	await process_frame
	quit()
