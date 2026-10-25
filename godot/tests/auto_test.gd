extends SceneTree
const Model = preload("res://scripts/race_model.gd")
var checks := 0
var failures := 0

func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(message)

func json_value(value):
	return JSON.parse_string(JSON.stringify(value, "", true, true))

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var m = Model.new()
	m.new_game(["ALICE", "BOB", "CAROL"], 123, Model.FORM)
	for i in range(6):
		m.field[i].odds = [8, 5, 2, 10, 2, 20][i]
		m.profiles[str(int(m.field[i].id))] = {"speed": 1, "stamina": 1, "consistency": 1}
	m.auto_strategy = Model.AUTO_FAVOURITE
	m.automatic_bets()
	check(m.players.all(func(p): return p.horse == 2 and p.kind == 0), "Favourite backs shortest odds to win; ties use lowest runner number")
	for strategy in [Model.AUTO_SECOND, Model.AUTO_MIDFIELD, Model.AUTO_OUTSIDE, Model.AUTO_UNDERDOG]:
		m.auto_strategy = strategy
		var expected: int = {Model.AUTO_SECOND: 2, Model.AUTO_MIDFIELD: 1, Model.AUTO_OUTSIDE: 3, Model.AUTO_UNDERDOG: 5}[strategy]
		check(m.automatic_horse() == expected, "Odds rank selector: " + strategy)
	m.auto_strategy = Model.AUTO_RATINGS
	var key := str(int(m.field[5].id))
	m.profiles[key] = {"speed": 5, "stamina": 5, "consistency": 5}
	m.automatic_bets()
	check(m.players.all(func(p): return p.horse == 5 and p.kind == 0), "Ratings selects stronger public ability even at longer odds")
	for strategy in Model.AUTO_FORM_ONLY:
		m.auto_strategy = strategy
		check(m.automatic_horse() == 5 if strategy != Model.AUTO_RECENT else m.automatic_horse() == 0, "Public form selector: " + strategy)
	m.auto_strategy = Model.AUTO_RATINGS
	for kind in range(3):
		for strategy in Model.AUTO_STRATEGIES:
			m.auto_kind = kind
			m.auto_strategy = strategy
			m.automatic_bets()
			check(m.players.all(func(p): return p.kind == kind), "Every selector honours chosen finish %d: %s" % [kind, strategy])
	m.auto_kind = 0
	m.auto_strategy = Model.AUTO_RATINGS
	var state: int = m.rng.state
	for horse in m.field:
		horse.race_form = 1.55 if horse == m.field[0] else 0.55
		horse.surge = 2.0
	m.automatic_bets()
	check(m.players[0].horse == 5 and m.rng.state == state, "Ratings ignores hidden form and does not consume racing RNG")
	for horse in m.field:
		m.profiles[str(int(horse.id))] = {"speed": 3, "stamina": 3, "consistency": 3}
	m.profiles[key].consistency = 5
	check(m.automatic_horse() == 5, "Consistency contributes to ratings selection")
	m.profiles[key].consistency = 3
	m.recent_results[key] = [{"rank": 1}]
	check(m.automatic_horse() == 5, "Recent finishes contribute to ratings selection")
	m.recent_results.clear()
	check(m.automatic_horse() == 0, "Ratings ties use lowest runner number")
	m.auto_stake = 0
	m.players[0].cash = 5350
	m.players[1].cash = 250
	m.players[2].cash = 199
	var sitting_out = m.players[2].duplicate(true)
	m.automatic_bets()
	check(m.players[0].stake == 500 and m.players[1].stake == 200, "Strategies retain proportional stakes and minimum")
	check(m.players[2] == sitting_out, "Players below minimum sit out")
	m.auto_stake = 1000000
	m.players[0].cash = 500000
	m.automatic_bets()
	check(m.players[0].stake == Model.MAX_BET and m.players[1].stake == 250, "Strategies respect stake and bankroll caps")
	m.auto_kind = 2
	m.auto_remaining = 3
	m.start_race()
	m.advance(1.3)
	var restored = Model.new()
	check(restored.restore(json_value(m.snapshot())) and restored.auto_strategy == Model.AUTO_RATINGS and restored.auto_kind == 2, "Save restores selected strategy and finish")
	m.advance(1000)
	restored.advance(1000)
	check(json_value(m.snapshot()) == json_value(restored.snapshot()), "Strategy save preserves exact race outcome")
	m.next_race()
	restored.next_race()
	m.automatic_bets()
	restored.automatic_bets()
	check(json_value(m.players) == json_value(restored.players), "Resumed strategy selects identical next-race bets")
	var legacy: Dictionary = m.snapshot()
	legacy.erase("auto_strategy")
	legacy.erase("auto_kind")
	check(restored.restore(json_value(legacy)) and restored.auto_strategy == Model.AUTO_RANDOM and restored.auto_kind == -1, "Older saves keep random auto behaviour")
	legacy.auto_strategy = "unknown"
	check(restored.restore(json_value(legacy)) and restored.auto_strategy == Model.AUTO_RANDOM, "Unknown strategy safely defaults to random")
	m.new_game(["ORIGINAL"], 5, Model.ORIGINAL)
	check(m.auto_strategy == Model.AUTO_FAVOURITE, "Switching to Original replaces unavailable ratings with Favourite")
	m.auto_strategy = Model.AUTO_RANDOM
	m.auto_kind = -1
	var horses := {}
	var kinds := {}
	for i in range(100):
		m.automatic_bets()
		horses[m.players[0].horse] = true
		kinds[m.players[0].kind] = true
	check(horses.size() == 6 and kinds.size() == 3, "Random still varies horse and bet type")
	await test_ui()
	print("Auto strategies: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)

func test_ui() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	game.settings_path = "user://auto-test.cfg"
	game.save_path = "user://auto-test-save.json"
	game.history_path = "user://auto-test-history.json"
	for path in [game.settings_path, game.save_path, game.history_path]:
		DirAccess.remove_absolute(path)
	root.add_child(game)
	game.sound_on = false
	game.set_process(false)
	game.start_new()
	check(game.auto_strategy_choice.item_count == Model.AUTO_STRATEGIES.size(), "UI includes every selector")
	for i in range(Model.AUTO_STRATEGIES.size()):
		check(game.auto_strategy_choice.is_item_disabled(i) == (Model.AUTO_STRATEGIES[i] in Model.AUTO_REMASTERED_ONLY), "Original mode availability: " + Model.AUTO_STRATEGIES[i])
	check(game.auto_strategy_choice.is_item_disabled(2), "Original visibly disables Form-only ratings")
	game.show_title()
	game.mode_choice.select(1)
	game.start_new()
	check(not game.auto_strategy_choice.is_item_disabled(2), "Form enables ratings")
	game.auto_strategy_choice.select(2)
	game.auto_strategy_choice.item_selected.emit(2)
	game.auto_kind_choice.select(1)
	game.auto_kind_choice.item_selected.emit(1)
	game.auto_count.value = 2
	game.toggle_auto()
	check(game.model.auto_strategy == Model.AUTO_RATINGS and game.model.players[0].kind == 1, "UI starts selected Place strategy")
	check(game.auto_button.text == "Cancel auto" and not game.auto_button.disabled, "Running auto exposes a named cancel button")
	check(game.auto_strategy_choice.disabled and game.status_label.text.contains("Form favourite / Place") and game.auto_kind_choice.disabled, "Running strategy is visible and locked during racing")
	game._process(1000)
	game.finish_results()
	check(game.model.phase == "RACING" and game.model.auto_remaining == 1, "Selected strategy continues automatically into next race")
	game.show_title()
	game.load_game()
	check(game.auto_strategy_choice.selected == 2 and game.auto_count.value == 1 and game.auto_kind_choice.selected == 1, "Continue restores strategy, finish and remaining race count")
	var racing_cash: int = game.model.players[0].cash
	game.auto_button.pressed.emit()
	check(game.model.auto_remaining == 0, "Existing stop control still works")
	check(game.model.phase == "RACING" and game.model.players[0].cash == racing_cash, "Cancelling preserves the current race and committed stake")
	check(game.auto_button.text == "Run auto" and game.auto_button.disabled, "Cancelled race cannot start auto again until settled")
	game.show_title()
	game.load_game()
	check(game.model.auto_remaining == 0, "Cancellation is saved immediately and survives Continue")
	game._process(1000)
	game.finish_results()
	check(not game.auto_strategy_choice.disabled, "Strategy can change after auto stops and race finishes")
	game.auto_count.value = 3
	game.toggle_auto()
	game._process(1000)
	check(game.model.phase == "RESULTS" and game.results_auto_button.text == "CANCEL AUTO", "Results popup offers cancellation before the next bet")
	var settled_cash: int = game.model.players[0].cash
	var settled_race: int = game.model.race_number
	game.results_auto_button.pressed.emit()
	check(game.model.auto_remaining == 0 and game.results_auto_button.disabled, "Results cancellation confirms automatic betting has stopped")
	await create_timer(3.2).timeout
	check(game.model.phase == "RESULTS" and game.model.race_number == settled_race and game.model.players[0].cash == settled_cash, "Pending results timers cannot place another bet after cancellation")
	game.finish_results()
	game.toggle_auto()
	var key := InputEventKey.new()
	key.keycode = KEY_A
	key.pressed = true
	game._unhandled_key_input(key)
	check(game.model.auto_remaining == 0 and game.auto_button.text == "Run auto", "Keyboard cancellation refreshes controls")
	var saved = JSON.parse_string(FileAccess.get_file_as_string(game.save_path))
	check(int(saved.auto_remaining) == 0, "Keyboard cancellation is persisted immediately")
	game._process(1000)
	game.finish_results()
	if "--capture" in OS.get_cmdline_user_args():
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://../docs/auto-strategies.png")
		game.show_help()
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://../docs/auto-help.png")
	for path in [game.settings_path, game.save_path, game.history_path]:
		DirAccess.remove_absolute(path)
	game.queue_free()
	await process_frame
