extends SceneTree
func _initialize() -> void:
	call_deferred("capture")
func shot(file_name: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://../docs/" + file_name)
func capture() -> void:
	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	main.sound_on = false
	main.save_path = "user://capture-form-save.json"
	main.history_path = "user://capture-form-records.json"
	main.mode_choice.select(1)
	main.update_mode_description()
	await shot("mode-selection.png")
	main.model.new_game(["MEGHANN", "PUNTER TWO"], 1245, "form")
	# Only actual simulated races supply the screenshot's recent form.
	for race_index in range(35):
		main.model.players[0].cash = 5000
		main.model.players[1].cash = 5000
		main.model.start_race()
		main.model.advance(1000)
		main.model.next_race()
	main.build_game()
	await shot("form-betting.png")
	main.show_racing_form()
	await shot("racing-form.png")
	main.close_modal()
	main.primary_action()
	main.model.advance(4.5)
	await shot("form-race.png")
	main.model.advance(1000)
	main.update_game()
	main.show_results()
	await shot("form-results.png")
	main.show_help()
	await shot("mode-help.png")
	for path in [main.save_path, main.history_path]:
		DirAccess.remove_absolute(path)
	main.queue_free()
	await process_frame
	quit()
