extends SceneTree
## Run against an exported PCK, not the source project's import cache.
var failures := 0

func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		push_error(message)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var args := OS.get_cmdline_user_args()
	# The delayed check verifies an already-open release after a rebuild.
	if args.size() >= 2 and args[0] == "--wait-for":
		var ready := FileAccess.open(args[1] + ".ready", FileAccess.WRITE)
		ready.store_string(OS.get_executable_path())
		ready.close()
		while not FileAccess.file_exists(args[1]):
			await create_timer(0.1).timeout
	var main = load("res://scenes/main.tscn").instantiate()
	var prefix := "user://pack-check-%d" % OS.get_process_id()
	main.settings_path = prefix + ".cfg"
	main.history_path = prefix + "-history.json"
	main.save_path = prefix + "-save.json"
	root.add_child(main)
	main.sound_on = false
	main.set_process(false)
	for mode in range(3):
		main.show_title()
		main.set_graphics_mode(mode)
		var portrait: Texture2D = main.title_portrait.texture
		check(portrait != null, "Pack contains title portrait for mode %d" % mode)
		if portrait:
			check(not portrait.get_image().is_empty(), "Portrait pixels decode from exported pack")
		if DisplayServer.get_name() != "headless":
			await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(OS.get_temp_dir() + "/nags-pack-title-mode-%d.png" % mode)
		main.model.new_game(["PACK CHECK"], 1245)
		main.build_game()
		check(main.track.frames.size() == (0 if mode == 2 else 30), "Pack supplies the selected horse graphics")
		for frame in main.track.frames:
			check(frame != null, "Sprite texture loads from pack")
			if frame:
				var pixels: Image = frame.get_image()
				check(pixels != null and not pixels.is_empty(), "Sprite pixels decode from exported pack")
		main.primary_action()
		main.model.advance(5)
		if DisplayServer.get_name() != "headless":
			await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(OS.get_temp_dir() + "/nags-pack-mode-%d.png" % mode)
	for path in [main.settings_path, main.history_path, main.save_path]:
		DirAccess.remove_absolute(path)
	main.queue_free()
	await process_frame
	print("Exported graphics: ", "PASS" if failures == 0 else "FAIL", " (", failures, " failures)")
	quit(0 if failures == 0 else 1)
