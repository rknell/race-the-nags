extends SceneTree
const Model = preload("res://scripts/race_model.gd")
const Simulation = preload("res://scripts/history_simulation.gd")
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
	var source = Model.new()
	source.new_game(["PUNTER"], 63, Model.ORIGINAL)
	source.stats["0"] = {"runs": 5, "wins": 2, "places": 1, "shows": 0}
	var before = json_value(source.snapshot())
	var simulation = Simulation.new(source.persistent_data(), 125)
	for i in range(Simulation.RACE_COUNT):
		simulation.run_next()
	check(json_value(source.snapshot()) == before, "Simulation leaves live visit, bankroll, field and RNG untouched")
	check(simulation.valid_races > 150, "Most background races are recorded")
	check(simulation.model.recent_results.size() > 150 and simulation.model.recent_results.size() < 217, "Many horses gain form while newcomers remain")
	var several := 0
	var starts := 0
	var wins := 0
	for key in simulation.model.stats:
		var record: Dictionary = simulation.model.stats[key]
		starts += int(record.runs)
		wins += int(record.wins)
		var history: Array = simulation.model.recent_results[key]
		check(history.size() <= 5 and not history.is_empty(), "History stays bounded")
		if history.size() >= 3:
			several += 1
	check(several > 140, "Most participating horses have several recent finishes")
	check(starts == simulation.valid_races * 6 and wins == simulation.valid_races, "Stats reflect fully settled six-runner races")
	check(simulation.model.records_by_mode[Model.ORIGINAL] == source.records_by_mode[Model.ORIGINAL], "Original records remain intact")
	source.load_persistent(json_value(simulation.persistent_data()))
	check(source.history_seeded, "One-time generation flag persists")
	check(json_value(source.profiles) == json_value(simulation.model.profiles), "Traits remain unchanged")
	var main = load("res://scenes/main.tscn").instantiate()
	main.settings_path = "user://history-test-settings.cfg"
	main.history_path = "user://history-test-records.json"
	main.save_path = "user://history-test-save.json"
	for path in [main.settings_path, main.history_path, main.save_path]:
		DirAccess.remove_absolute(path)
	root.add_child(main)
	await process_frame
	main.sound_on = false
	check(not main.history_button.visible, "History generation is exclusive to Remastered")
	main.mode_choice.select(1)
	main.set_game_mode(1)
	check(main.history_button.visible and not main.history_button.disabled, "Remastered home offers generation")
	main.start_new()
	var saved_field = json_value(main.model.field)
	var saved_players = json_value(main.model.players)
	var saved_rng: int = main.model.rng.state
	main.show_title()
	main.show_history_simulation()
	main.run_history_simulation()
	main.close_modal()
	await process_frame
	await process_frame
	check(not main.model.history_seeded and main.model.recent_results.is_empty(), "Cancelling discards unfinished simulation")
	await main.run_history_simulation()
	check(main.model.history_seeded and main.history_button.disabled, "Generation completes and prevents repeat clicks")
	check(main.fame.is_empty() and main.million.is_empty(), "Background meetings produce no player scores")
	var history = json_value(main.model.recent_results)
	main.load_game()
	check(json_value(main.model.recent_results) == history, "Continue inherits generated history from a pre-generation save")
	check(json_value(main.model.field) == saved_field and json_value(main.model.players) == saved_players and main.model.rng.state == saved_rng, "Continue preserves booked field, prices, bankroll and RNG")
	check(main.model.total_races > 150, "Continue inherits generated statistics")
	main.save_game(false)
	main.model = Model.new()
	main.load_history()
	check(main.model.history_seeded and json_value(main.model.recent_results) == history, "Generation and flag survive records-file reload")
	main.load_game()
	check(json_value(main.model.recent_results) == history, "Re-saved visit retains generated form")
	for path in [main.settings_path, main.history_path, main.save_path]:
		DirAccess.remove_absolute(path)
	main.queue_free()
	await process_frame
	print("History simulation: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)
