extends SceneTree
var failures := 0
func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		push_error(message)
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var main = load("res://scenes/main.tscn").instantiate()
	main.settings_path = "user://ui_test-settings.cfg"
	DirAccess.remove_absolute(main.settings_path)
	main.save_path = "user://ui-test-save.json"
	main.history_path = "user://ui-test-history.json"
	DirAccess.remove_absolute(main.history_path)
	root.add_child(main)
	await process_frame
	main.sound_on = false
	main.fame.clear()
	main.million.clear()
	for i in range(6):
		main.names[i].text = "PUNTER %d" % i
	main.start_new()
	await process_frame
	check(main.model.players.size() == 6, "Six-player setup")
	check(main.track.frames.size() == 30, "Recovered sprite textures loaded")
	main.bet_rows[0].amount.value = 10
	main.bet_rows[0].horse.select(3)
	main.bet_rows[0].kind.select(2)
	main.sync_bets()
	check(main.bet_rows[0].summary.text.contains("$10.00 on #4"), "Bet summary identifies stake and runner")
	check(main.bet_rows[0].summary.text.contains("SHOW · needs top 3"), "Bet summary explains selected finish")
	check(main.track.backers(3).has("PUNTER 0") and not main.track.backers(0).has("PUNTER 0"), "Lane marker follows edited pick")
	main.primary_button.pressed.emit()
	check(main.model.phase == "RACING", "Start button begins race")
	check(main.model.players[0].cash == 4000, "Bet deducted once")
	check(main.model.players[0].horse == 3 and main.model.players[0].kind == 2, "UI bet selection applied")
	main.model.advance(2)
	var before: Dictionary = main.model.snapshot()
	main.save_game()
	main.show_title()
	main.load_game()
	check(JSON.parse_string(JSON.stringify(main.model.snapshot(), "", true, true)) == JSON.parse_string(JSON.stringify(before, "", true, true)), "UI save/resume roundtrip")
	check(main.bet_rows[0].horse.disabled, "Race disables editing")
	check(main.track.backers(3).has("PUNTER 0"), "Backed lane survives save/resume")
	main.show_help()
	await process_frame
	await process_frame
	var help_scroll: ScrollContainer = main.dialog_layer.find_child("HelpScroll", true, false)
	check(help_scroll != null, "Help has a scrollable reading area")
	if help_scroll:
		var bar := help_scroll.get_v_scroll_bar()
		check(bar.max_value > bar.page, "Overflowing help can scroll")
		var wheel := InputEventMouseButton.new()
		wheel.button_index = MOUSE_BUTTON_WHEEL_DOWN
		wheel.pressed = true
		wheel.position = help_scroll.get_global_rect().get_center()
		var motion := InputEventMouseMotion.new()
		motion.position = wheel.position
		root.push_input(motion, true)
		root.push_input(wheel, true)
		await process_frame
		check(help_scroll.scroll_vertical > 0, "Mouse wheel scrolls help text")
		help_scroll.scroll_vertical = int(bar.max_value)
		await process_frame
		check(help_scroll.scroll_vertical > 0, "Help scrolls to the final lines")
		var content := help_scroll.get_child(0) as Label
		check(content.get_global_rect().end.y <= help_scroll.get_global_rect().end.y + 1, "Final help line is reachable")
		check(help_scroll.get_h_scroll_bar().visible == false, "Help wraps without horizontal scrolling")
	var paused: float = main.model.elapsed
	main._process(1.0)
	check(main.model.elapsed == paused, "Modal pauses race")
	main.close_modal()
	main.model.advance(1000)
	main.update_game()
	main.show_results()
	check(main.model.phase == "RESULTS" and main.dialog_layer != null, "Results modal shown")
	main.finish_results()
	main.primary_button.pressed.emit()
	check(main.model.phase == "BETTING" and main.model.race_number == 2, "Next race returns to betting")
	main.auto_count.value = 2
	main.toggle_auto()
	check(main.model.phase == "RACING" and main.model.auto_remaining == 2, "Automatic mode starts")
	main._process(1000)
	check(main.model.phase == "RESULTS" and main.model.auto_remaining == 1, "Automatic race counts down")
	main.finish_results()
	check(main.model.phase == "RACING", "Auto advances with selected bets")
	main._process(1000)
	check(main.model.phase == "RESULTS" and main.model.auto_remaining == 0, "Automatic mode ends at requested count")
	main.finish_results()
	main.go_home()
	check(not main.in_game and main.fame.size() == 6, "Go home records scores")
	for path in [main.save_path, main.history_path, main.settings_path]:
		DirAccess.remove_absolute(path)
	main.queue_free()
	await process_frame
	print("UI integration: ", "PASS" if failures == 0 else "FAIL", " (", failures, " failures)")
	quit(0 if failures == 0 else 1)
