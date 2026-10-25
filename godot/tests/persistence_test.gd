extends SceneTree
var failures := 0
var checks := 0
const SETTINGS := "user://persistence-test.cfg"
const SAVE := "user://persistence-test-save.json"
const HISTORY := "user://persistence-test-records.json"

func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(message)

func _initialize() -> void:
	call_deferred("run")

func open_game():
	var game = load("res://scenes/main.tscn").instantiate()
	game.settings_path = SETTINGS
	game.save_path = SAVE
	game.history_path = HISTORY
	root.add_child(game)
	game.audio.volume_db = -80
	game.set_process(false)
	return game

func saved() -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string(SAVE))

func run() -> void:
	for path in [SETTINGS, SAVE, HISTORY]:
		DirAccess.remove_absolute(path)
	var game = open_game()
	check(game.names[0].text.is_empty(), "First run starts with empty names")
	check(game.mode_choice.selected == 0 and game.graphics_choice.selected == 0, "First run defaults to Original and Classic")
	check(game.sound_on, "Sound defaults to on")
	game.toggle_sound()
	game.mode_choice.select(1)
	game.mode_choice.item_selected.emit(1)
	game.names[0].text = "Alice"
	game.names[2].text = "Bob"
	game.names[2].text_changed.emit("Bob")
	game.set_graphics_mode(1)
	game.queue_free()
	await process_frame
	game = open_game()
	check(game.names[0].text == "Alice" and game.names[1].text == "" and game.names[2].text == "Bob", "Names and empty slots survive restart before playing")
	check(game.graphics_mode == 1, "Names and graphics settings coexist")
	check(game.mode_choice.selected == 1, "Game type survives restart before playing")
	check(not game.sound_on, "Sound off survives restart before playing")
	game.mode_choice.select(1)
	game.start_new()
	check(saved().players.size() == 2 and saved().mode == "form", "Starting a visit creates a resumable game")
	game.bet_rows[0].amount.value = 7
	game.bet_rows[0].horse.select(3)
	game.primary_action()
	check(saved().phase == "RACING" and saved().players[0].cash == 4300 and saved().players[0].horse == 3, "Starting race autosaves bets and deducted stakes")
	game.model.advance(2)
	check(game.save_game(), "Mid-race save succeeds")
	var expected = JSON.parse_string(JSON.stringify(game.model.snapshot(), "", true, true))
	game.queue_free()
	await process_frame
	# Simulate an upgrade: names come from an older save without a settings key.
	var settings := ConfigFile.new()
	settings.load(SETTINGS)
	settings.erase_section_key("players", "names")
	settings.save(SETTINGS)
	game = open_game()
	check(game.names[0].text == "ALICE" and game.names[1].text == "BOB", "Existing saves supply last session's player names")
	game.mode_choice.select(0)
	game.mode_choice.item_selected.emit(0)
	game.load_game()
	check(JSON.parse_string(JSON.stringify(game.model.snapshot(), "", true, true)) == expected, "Restart and Continue restore exact mid-race state and RNG")
	game._process(1000)
	check(saved().phase == "RESULTS", "Finishing race autosaves results")
	game.finish_results()
	game.primary_action()
	check(saved().phase == "BETTING" and saved().race_number == 2, "Next race autosaves new field")
	game.bet_rows[0].amount.value = 3
	game.go_home()
	check(not game.in_game and saved().players[0].stake == 300, "Go home saves latest betting edits")
	game.queue_free()
	await process_frame
	game = open_game()
	check(game.mode_choice.selected == 0 and game.graphics_choice.selected == 1, "Latest choices survive restart independently of the saved game's mode")
	game.load_game()
	check(game.model.race_number == 2 and game.model.players[0].stake == 300, "Go home then restart retains bankrolls and next race")
	var good_save := FileAccess.get_file_as_string(SAVE)
	game.save_path = "user://missing-persistence-test-dir/save.json"
	check(not game.save_game(), "Unwritable destination reports save failure")
	check(FileAccess.get_file_as_string(SAVE) == good_save, "Failed save preserves previous saved game")
	game.save_path = SAVE
	game.show_title()
	for edit in game.names:
		edit.text = ""
	game.names[0].text_changed.emit("")
	game.queue_free()
	await process_frame
	game = open_game()
	check(game.names.all(func(edit): return edit.text.is_empty()), "Clearing names stays cleared despite an existing save")
	game.set_graphics_mode(2)
	game.queue_free()
	await process_frame
	game = open_game()
	check(game.graphics_choice.selected == 2 and game.mode_choice.selected == 0, "Animated graphics and Original survive restart together")
	game.queue_free()
	await process_frame
	settings.load(SETTINGS)
	settings.set_value("game", "mode", "unknown")
	settings.set_value("graphics", "mode", "unknown")
	settings.save(SETTINGS)
	game = open_game()
	check(game.mode_choice.selected == 0 and game.graphics_choice.selected == 0, "Unknown preferences fall back to Original and Classic")
	game.toggle_sound()
	game.start_new()
	game.auto_strategy_choice.select(1)
	game.auto_strategy_choice.item_selected.emit(1)
	game.auto_kind_choice.select(2)
	game.auto_kind_choice.item_selected.emit(2)
	game.auto_count.value = 37
	game.auto_amount.value = 0
	game.queue_free()
	await process_frame
	game = open_game()
	check(game.sound_on, "Sound on survives restart")
	game.start_new()
	check(game.model.auto_strategy == "favourite" and game.model.auto_kind == 2 and game.auto_count.value == 37 and game.auto_amount.value == 0, "Auto choices persist before running any automatic races")
	check(game.model.auto_remaining == 0, "Remembering auto settings does not start automatic play")
	game.show_title()
	game.mode_choice.select(1)
	game.start_new()
	check(game.model.auto_strategy == "random" and game.model.auto_kind == 0 and game.auto_count.value == 10 and game.auto_amount.value == 2, "Remastered has independent auto defaults")
	game.auto_strategy_choice.select(7)
	game.auto_strategy_choice.item_selected.emit(7)
	game.auto_kind_choice.select(4)
	game.auto_kind_choice.item_selected.emit(4)
	game.auto_count.value = 6
	game.auto_amount.value = 12
	game.queue_free()
	await process_frame
	game = open_game()
	game.start_new()
	check(game.model.auto_strategy == "speed" and game.model.auto_kind == 4 and game.auto_count.value == 6 and game.auto_amount.value == 12, "Remastered strategy, multi-horse bet, race count and stake survive restart")
	game.show_title()
	game.mode_choice.select(0)
	game.start_new()
	check(game.model.auto_strategy == "favourite" and game.model.auto_kind == 2 and game.auto_count.value == 37 and game.auto_amount.value == 0, "Switching modes retains each mode's auto preferences")
	game.queue_free()
	await process_frame
	for path in [SETTINGS, SAVE, SAVE + ".tmp", HISTORY]:
		DirAccess.remove_absolute(path)
	print("Persistence integration: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)
