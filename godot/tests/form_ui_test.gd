extends SceneTree
const Model = preload("res://scripts/race_model.gd")
var checks := 0
var failures := 0
func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(message)
func _initialize() -> void:
	call_deferred("run")
func all_text(node: Node) -> String:
	var value := ""
	if node is Label:
		value = node.text + "\n"
	for child in node.get_children():
		value += all_text(child)
	return value
func run() -> void:
	var main = load("res://scenes/main.tscn").instantiate()
	main.settings_path = "user://form_ui_test-settings.cfg"
	DirAccess.remove_absolute(main.settings_path)
	main.save_path = "user://form-ui-test-save.json"
	main.history_path = "user://form-ui-test-records.json"
	DirAccess.remove_absolute(main.history_path)
	root.add_child(main)
	await process_frame
	main.sound_on = false
	main.fame.clear()
	main.million.clear()
	check(main.mode_choice.item_count == 2, "Two game modes offered")
	check(main.mode_choice.selected == 0, "Original remains default")
	main.mode_choice.select(1)
	for i in range(6):
		main.names[i].text = "FORM %d" % i
	main.start_new()
	check(main.model.mode == Model.FORM, "Title selection starts Form")
	check(main.recent_labels.size() == 6, "Six recent-result summaries shown")
	check(main.recent_labels[0].text.contains("No starts yet"), "Unraced horse shows honest empty history")
	main.show_racing_form()
	var public_text := all_text(main.dialog_layer)
	check(public_text.contains("SPEED") and public_text.contains("STAMINA") and public_text.contains("CONSISTENCY"), "Form card exposes all public traits")
	check(not public_text.contains("race_form") and not public_text.contains("surge_until"), "No private fields displayed")
	main.close_modal()
	main.bet_rows[0].horse.select(2)
	main.primary_action()
	main.model.advance(2)
	main.save_game()
	var form_value: float = main.model.field[2].race_form
	main.show_title()
	main.mode_choice.select(0)
	main.load_game()
	check(main.model.mode == Model.FORM, "Continue uses saved mode, regardless of picker")
	check(absf(main.model.field[2].race_form - form_value) < 1.0e-12, "Continue preserves hidden form")
	main._process(1000)
	check(main.model.phase == "RESULTS", "Form race reaches results through UI")
	check(not main.model.recent_results.is_empty(), "Race adds history")
	main.finish_results()
	main.show_racing_form()
	check(not all_text(main.dialog_layer).contains("No starts yet"), "Completed race appears on all six cards")
	main.close_modal()
	var saved_history: Dictionary = main.model.recent_results.duplicate(true)
	main.go_home()
	check(main.fame.size() == 6 and main.fame[0].mode == Model.FORM, "High scores tagged with game mode")
	main.model = Model.new()
	main.load_history()
	main.mode_choice.select(1)
	main.start_new()
	check(JSON.parse_string(JSON.stringify(main.model.recent_results)) == JSON.parse_string(JSON.stringify(saved_history)), "History survives records-file reload")
	check(main.model.total_races >= 1, "Form statistics survive records-file reload")
	main.go_home()
	main.mode_choice.select(0)
	main.start_new()
	check(main.model.mode == Model.ORIGINAL, "Original remains selectable after Form")
	check(main.recent_labels[0].text.is_empty(), "Original does not show Form history")
	main.show_fame()
	check(all_text(main.dialog_layer).contains("A clean slate"), "Form scores excluded from Original leaderboard")
	main.close_modal()
	main.save_game()
	main.show_title()
	main.mode_choice.select(1)
	main.load_game()
	check(main.model.mode == Model.ORIGINAL, "Original save restores from Form picker")
	for path in [main.save_path, main.history_path, main.settings_path]:
		DirAccess.remove_absolute(path)
	main.queue_free()
	await process_frame
	print("Form UI integration: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)
