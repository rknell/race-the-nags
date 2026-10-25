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
	m.new_game(["A", "B", "C", "D"], 100, Model.FORM)
	check(m.mode_name() == "Remastered", "Enhanced mode is named Remastered")
	for i in range(6):
		m.field[i].odds = i + 2
	for kind in range(3, 7):
		var runners := [0, 1] if kind < 5 else [0, 1, 2]
		check(m.set_bet(kind - 3, 0, kind, 200, runners), "Can place exotic ticket")
		check(not m.set_bet(0, 0, kind, 200, [0, 0]), "Duplicate runner rejected")
		check(not m.set_bet(0, 0, kind, 200, [0, 6, 2]), "Invalid runner rejected")
		check(not m.set_bet(0, 1, kind, 200, runners), "First pick must match primary horse")
	check(m.exotic_quote(200, Model.QUINELLA, [0, 1]) == 600, "Quinella quote covers two orders")
	check(m.exotic_quote(200, Model.EXACTA, [0, 1]) == 1200, "Exacta quote")
	check(m.exotic_quote(200, Model.TRIFECTA, [0, 1, 2]) == 4800, "Trifecta quote")
	check(m.exotic_quote(200, Model.BOX_TRIFECTA, [0, 1, 2]) == 800, "Box quote includes six orders in total stake")
	for first in range(6):
		for second in range(6):
			for third in range(6):
				if first == second or second == third or first == third:
					continue
				m.finish_order = [first, second, third]
				var top_two := [first, second]
				top_two.sort()
				var top_three := [first, second, third]
				top_three.sort()
				check(m.exotic_wins(Model.QUINELLA, [0, 1]) == (top_two == [0, 1]), "Quinella order matching")
				check(m.exotic_wins(Model.EXACTA, [0, 1]) == (first == 0 and second == 1), "Exacta order matching")
				check(m.exotic_wins(Model.TRIFECTA, [0, 1, 2]) == (m.finish_order == [0, 1, 2]), "Trifecta order matching")
				check(m.exotic_wins(Model.BOX_TRIFECTA, [0, 1, 2]) == (top_three == [0, 1, 2]), "Box order matching")
	m.finish_order = []
	check(m.start_race(), "Exotic tickets start race")
	check(m.players.all(func(p): return p.cash == 4800), "Total ticket stake deducted once")
	var resumed = Model.new()
	check(resumed.restore(json_value(m.snapshot())), "Save restores all ticket types")
	m.finish_order = [0, 1, 2, 3, 4, 5]
	m.settle_race()
	check(m.players[0].cash == 5400 and m.players[1].cash == 6000 and m.players[2].cash == 9600 and m.players[3].cash == 5600, "Each winning ticket credits quoted return")
	resumed.finish_order = [0, 1, 2, 3, 4, 5]
	resumed.settle_race()
	check(json_value(m.snapshot()) == json_value(resumed.snapshot()), "Resumed settlement matches exactly")
	resumed = Model.new()
	var damaged: Dictionary = m.snapshot()
	damaged.players[0].runners = [0, 0]
	check(not resumed.restore(json_value(damaged)), "Save validation rejects repeated picks")
	for strategy in Model.AUTO_STRATEGIES:
		for kind in range(3, 7):
			m.new_game(["AUTO"], 321, Model.FORM)
			m.auto_strategy = strategy
			m.auto_kind = kind
			m.automatic_bets()
			check(Model.valid_runners(kind, m.ticket_runners(m.players[0])), "Auto always selects distinct valid horses: " + strategy)
			check(m.start_race(), "Auto exotic starts")
			var restored = Model.new()
			check(restored.restore(json_value(m.snapshot())) and restored.auto_kind == kind, "Auto bet type restores")
			m.advance(1000)
			restored.advance(1000)
			check(json_value(m.snapshot()) == json_value(restored.snapshot()), "Auto race resumes deterministically")
	m.new_game(["VOID"], 321, Model.FORM)
	m.set_bet(0, 0, Model.TRIFECTA, 200, [0, 1, 2])
	m.start_race()
	m.void_race = true
	m.settle_race()
	check(m.players[0].cash == 5000, "Voided exotic refunds whole ticket")
	m.new_game(["FALL"], 321, Model.FORM)
	m.set_bet(0, 0, Model.BOX_TRIFECTA, 200, [0, 1, 2])
	m.start_race()
	m.field[2].fallen = true
	m.finish_order = [0, 1, 3, 4, 5]
	m.settle_race()
	check(m.results[0]["return"] == 0, "Fallen selected runner loses combination")
	m.auto_kind = Model.TRIFECTA
	m.new_game(["ORIGINAL"], 321, Model.ORIGINAL)
	check(m.auto_kind == 0, "Original resets unavailable auto bet to Win")
	for kind in range(3, 7):
		check(not m.set_bet(0, 0, kind, 200, [0, 1, 2]), "Original rejects exotic bet")
	var original: Dictionary = m.snapshot()
	original.players[0].kind = Model.QUINELLA
	original.players[0].runners = [0, 1]
	check(not resumed.restore(json_value(original)), "Original save cannot inject exotic ticket")
	await test_ui()
	print("Remastered bets: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)

func test_ui() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	var prefix := "user://remastered-bets-test"
	game.settings_path = prefix + ".cfg"
	game.save_path = prefix + ".json"
	game.history_path = prefix + "-history.json"
	for path in [game.settings_path, game.save_path, game.history_path]:
		DirAccess.remove_absolute(path)
	root.add_child(game)
	game.sound_on = false
	game.set_process(false)
	game.start_new()
	check(game.bet_rows[0].kind.item_count == 3 and game.auto_kind_choice.item_count == 4, "Original UI offers only existing bets")
	game.show_title()
	check(game.mode_choice.get_item_text(1).contains("Remastered"), "Title names Remastered")
	game.mode_choice.select(1)
	game.start_new()
	check(game.bet_rows[0].kind.item_count == 7 and game.auto_kind_choice.item_count == 8, "Remastered offers all bets and auto")
	game.bet_rows[0].kind.select(Model.TRIFECTA)
	game.bet_rows[0].kind.item_selected.emit(Model.TRIFECTA)
	check(game.dialog_layer != null and game.ticket_choices.size() == 3, "Trifecta opens three-horse picker")
	game.ticket_choices[0].select(2)
	game.ticket_choices[0].item_selected.emit(2)
	check(game.ticket_apply.disabled, "Picker blocks duplicate horses")
	game.ticket_choices[2].select(4)
	game.ticket_choices[2].item_selected.emit(4)
	check(not game.ticket_apply.disabled and game.ticket_preview.text.contains("Return if won"), "Valid picker shows quoted return")
	if "--capture" in OS.get_cmdline_user_args():
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://../docs/remastered-ticket.png")
	game.ticket_apply.pressed.emit()
	check(game.model.ticket_runners(game.model.players[0]) == [2, 1, 4], "Confirm applies ordered picks")
	check(game.bet_rows[0].selection.visible and not game.bet_rows[0].horse.visible, "Multi-horse edit replaces single-horse selector")
	check(game.track.backers(2).has("PLAYER 1") and game.track.backers(1).has("PLAYER 1") and game.track.backers(4).has("PLAYER 1"), "All selected horses marked on track")
	check(game.bet_rows[0].summary.text.contains("Trifecta #3 / #2 / #5 (in order)"), "Slip explains ticket")
	game.save_game(false)
	game.show_title()
	game.load_game()
	check(game.model.ticket_runners(game.model.players[0]) == [2, 1, 4] and game.bet_rows[0].selection.visible, "Continue restores manual ticket UI")
	check(game.track.backers(2).has("PLAYER 1") and game.track.backers(4).has("PLAYER 1"), "Restored ticket retains every track marker")
	game.auto_kind_choice.select(Model.BOX_TRIFECTA)
	game.auto_kind_choice.item_selected.emit(Model.BOX_TRIFECTA)
	game.auto_count.value = 2
	game.toggle_auto()
	check(game.model.phase == "RACING" and game.model.players[0].kind == Model.BOX_TRIFECTA, "Auto starts boxed ticket")
	game._process(1000)
	game.finish_results()
	check(game.model.phase == "RACING" and game.model.auto_remaining == 1, "Auto generates next ticket")
	game.toggle_auto()
	game._process(1000)
	game.finish_results()
	if "--capture" in OS.get_cmdline_user_args():
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://../docs/remastered-bets.png")
		game.show_help()
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://../docs/remastered-help.png")
	for path in [game.settings_path, game.save_path, game.history_path]:
		DirAccess.remove_absolute(path)
	game.queue_free()
	await process_frame
