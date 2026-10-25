extends SceneTree
const Model = preload("res://scripts/race_model.gd")
var failures := 0
var checks := 0

func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(message)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	for mode in [Model.ORIGINAL, Model.FORM]:
		var hits := [0, 0, 0, 0, 0, 0]
		for seed_value in range(600):
			var m = Model.new()
			m.new_game(["TEST"], seed_value, mode)
			check(m.fire_bazooka() == -1, "Cannot fire before the start")
			m.start_race()
			check(m.fire_bazooka() == -1, "New players do not see the secret")
			m.played_races = 3
			m.field[5].position = 500.0
			var target: int = m.fire_bazooka()
			hits[target] += 1
			check(m.field[target].fallen and m.field[target].blasted, "Hit runner is out")
			check(m.fire_bazooka() == -1, "One shared shot per race")
			var restored = Model.new()
			check(restored.restore(JSON.parse_string(JSON.stringify(m.snapshot(), "", true, true))), "Shot survives disk-format restore")
			check(restored.bazooka_used and restored.bazooka_target == target and restored.fire_bazooka() == -1, "Reload cannot replenish ammo")
			while m.phase == "RACING":
				m.advance(1.0)
			while restored.phase == "RACING":
				restored.advance(1.0)
			check(m.finish_order == restored.finish_order and m.players[0].cash == restored.players[0].cash, "Shot race resumes deterministically")
			check(not target in m.finish_order, "Blasted horse cannot place")
			check(m.played_races == 4, "Settling counts one played race")
			m.next_race()
			m.start_race()
			check(m.bazooka_available(), "Next race replenishes ammo")
		for count in hits:
			check(count > 65 and count < 135, "Every runner, including own bet and leader, has equal targeting opportunity")
		var m = Model.new()
		m.new_game(["TEST"], 123, mode)
		m.played_races = 3
		m.start_race()
		m.field[0].fallen = true
		m.field[1].fallen = true
		m.field[2].fallen = true
		var target: int = m.fire_bazooka()
		check(target >= 3 and m.void_race and m.settled, "Fourth elimination voids immediately")
		check(m.players[0].cash == 5000, "Voided rocket race refunds stake")
		m.settle_race()
		check(m.players[0].cash == 5000 and m.played_races == 4, "Settlement cannot duplicate refunds or progress")
		m.next_race()
		m.start_race()
		m.field[0].finished = true
		m.finish_order.append(0)
		for i in range(1, 5):
			m.field[i].fallen = true
		check(m.fire_bazooka() == 5 and m.finish_order == [0], "Finished and fallen horses are excluded")
	var main = load("res://scenes/main.tscn").instantiate()
	main.settings_path = "user://bazooka-test.cfg"
	main.save_path = "user://bazooka-test-save.json"
	main.history_path = "user://bazooka-test-history.json"
	root.add_child(main)
	await process_frame
	main.sound_on = false
	main.start_new()
	main.model.played_races = 3
	main.primary_action()
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	click.position = main.track.crate_rect().get_center()
	main.toggle_pause()
	main.track._gui_input(click)
	check(not main.model.bazooka_used, "Paused races reject crate clicks")
	main.close_modal()
	main.track._gui_input(click)
	check(main.model.bazooka_used and main.track.blast_lane >= 0, "Crate click launches rocket feedback")
	check(main.notice.text.contains("Stray rocket!"), "Shot reports which horse was hit")
	main.show_title()
	main.load_game()
	check(main.model.bazooka_used and main.model.played_races >= 3, "UI autosaves ammo and discovery progress")
	for path in [main.settings_path, main.save_path, main.history_path]:
		DirAccess.remove_absolute(path)
	main.queue_free()
	await process_frame
	print("Bazooka: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
