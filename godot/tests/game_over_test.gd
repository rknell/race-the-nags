extends SceneTree
var failures := 0

func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		push_error(message)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	game.settings_path = "user://game-over-test.cfg"
	game.save_path = "user://game-over-test-save.json"
	game.history_path = "user://game-over-test-records.json"
	for path in [game.settings_path, game.save_path, game.history_path]:
		DirAccess.remove_absolute(path)
	root.add_child(game)
	game.set_process(false)
	game.fame.clear()
	for mode in ["original", "form"]:
		game.names[0].text = "ALICE"
		game.names[1].text = "BOB"
		game.mode_choice.select(1 if mode == "form" else 0)
		game.start_new()
		# Predict a losing horse using a restored copy, then genuinely settle all-in bets.
		var prediction = game.Model.new()
		prediction.restore(game.model.snapshot())
		prediction.start_race()
		prediction.advance(1000)
		var loser := (int(prediction.finish_order[0]) + 1) % 6
		for row in game.bet_rows:
			row.amount.value = 50
			row.horse.select(loser)
			row.kind.select(0)
		game.model.auto_remaining = 20
		game.primary_action()
		check(not game.model.can_play(), "All-in stakes temporarily empty bankrolls")
		game.show_game_over()
		check(game.in_game and not game.game_over_active, "Unsettled all-in race must continue")
		game._process(1000)
		check(game.game_over_active and not game.in_game, "%s: losing settlement opens scoreboard" % mode)
		check(game.model.auto_remaining == 0, "Bankruptcy stops automatic racing")
		check(not FileAccess.file_exists(game.save_path), "Finished visit cannot be resumed")
		check(game.audio.stream is AudioStreamWAV and game.audio.stream.get_length() > 5, "Death tune is a full synthesized phrase")
		if "--capture" in OS.get_cmdline_user_args() and mode == "original":
			await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://../docs/game-over-screen.png")
		var records: int = game.fame.size()
		game.show_game_over()
		game.finish_results()
		game.toggle_auto()
		check(game.fame.size() == records, "Repeated callbacks cannot record visit twice")
		game._process(11)
		check(game.game_over_active, "Scoreboard stays visible for reading")
		game._process(2)
		check(not game.game_over_active and not game.in_game and game.names[0].text == "ALICE", "Returns home with names remembered")
		game.start_new()
		check(game.in_game and game.model.players[0].cash == 5000, "Restart restores $50")
		game.model.players[0].cash = 0
		game.model.players[1].cash = 200
		game.show_game_over()
		check(game.in_game, "Another player's minimum stake keeps multiplayer alive")
		game.model.players[1].cash = 199
		game.save_game(false)
		game.show_title()
		game.load_game()
		check(game.game_over_active, "Legacy bankrupt betting save goes to scoreboard")
		game.toggle_sound()
		check(not game.audio.playing, "Sound toggle silences death music")
		game.show_title()
		game.sound_on = true
	check(game.fame.size() == 8, "Each ended visit records both players once across both modes")
	for path in [game.settings_path, game.save_path, game.history_path]:
		DirAccess.remove_absolute(path)
	game.queue_free()
	await process_frame
	print("Game over integration: ", "PASS" if failures == 0 else "FAIL", " (", failures, " failures)")
	quit(0 if failures == 0 else 1)
