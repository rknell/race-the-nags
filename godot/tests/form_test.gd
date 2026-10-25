extends SceneTree
const Model = preload("res://scripts/race_model.gd")
const Form = preload("res://scripts/form_racing.gd")
var checks := 0
var failures := 0

func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(message)

func json_value(value):
	return JSON.parse_string(JSON.stringify(value, "", true, true))

func fresh(seed_value: int = 987):
	var model = Model.new()
	model.new_game(["FORM PLAYER"], seed_value, Model.FORM)
	return model

func finish(model) -> bool:
	for tick in range(12000):
		if model.phase != "RACING":
			return model.phase == "RESULTS"
		model.step_race()
	return false

func _initialize() -> void:
	test_original_regression()
	test_profiles_and_public_card()
	test_ballot()
	test_history()
	test_save_and_migration()
	test_late_save()
	test_many_races()
	print("Form tests: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)

func test_original_regression() -> void:
	var f := FileAccess.open("res://tests/original-baseline.json", FileAccess.READ)
	var fixtures = JSON.parse_string(f.get_as_text())
	for fixture in fixtures:
		var model = Model.new()
		model.new_game(["ALICE", "BOB"], int(fixture.seed), Model.ORIGINAL)
		check(json_value(model.field) == fixture.initial, "Original field RNG unchanged")
		model.start_race()
		model.advance(1000)
		check(json_value(model.field) == fixture.field, "Original movement and falls unchanged")
		check(json_value(model.players) == fixture.players, "Original payout unchanged")
		check(json_value(model.finish_order) == fixture.finish_order, "Original finish order unchanged")
		check(str(model.rng.state) == fixture.rng_state, "Original RNG consumption unchanged")

func test_profiles_and_public_card() -> void:
	var a = fresh(4)
	var b = fresh(9999)
	check(a.profiles == b.profiles, "Traits independent of session seed")
	check(a.profiles.size() == 217, "Every horse has persistent traits")
	for profile in a.profiles.values():
		for key in ["speed", "stamina", "consistency"]:
			check(int(profile[key]) >= 1 and int(profile[key]) <= 5, "Trait is on 1..5 scale")
	var profiles: Dictionary = a.profiles.duplicate(true)
	a.new_game(["AGAIN"], 11, Model.FORM)
	check(a.profiles == profiles, "New visit does not reroll traits")
	var public_before: Dictionary = a.racing_card(0)
	check(not public_before.has("race_form") and not public_before.has("surge"), "Card excludes hidden state")
	var quotes := Form.quote_odds(a.field, a.profiles, a.recent_results, 46)
	a.field[0].race_form = 1.55
	a.field[1].race_form = 0.55
	check(a.racing_card(0) == public_before, "Changing hidden daily form does not leak through card")
	check(Form.quote_odds(a.field, a.profiles, a.recent_results, 46) == quotes, "Published odds never read hidden form")
	var speed_low := {"speed": 1, "stamina": 3, "consistency": 3}
	var speed_high := {"speed": 5, "stamina": 3, "consistency": 3}
	check(Form.pace(speed_high, 0.5) > Form.pace(speed_low, 0.5), "Speed raises ballot weight")
	check(Form.pace({"speed": 3, "stamina": 5}, 1.0) > Form.pace({"speed": 3, "stamina": 1}, 1.0), "Stamina helps late")
	check(Form.form_spread({"consistency": 5}) < Form.form_spread({"consistency": 1}), "Consistency reduces form variance")
	var lower_quote_profiles := {}
	for i in range(6):
		lower_quote_profiles[str(int(a.field[i].id))] = {"speed": 1, "stamina": 1, "consistency": 5}
	lower_quote_profiles[str(int(a.field[0].id))] = {"speed": 5, "stamina": 5, "consistency": 5}
	var quality_quotes := Form.quote_odds(a.field, lower_quote_profiles, {}, 411)
	check(quality_quotes[0] < quality_quotes[1], "Publicly stronger horse receives shorter quoted odds")
	var weight_before := float(Form.ballot_weights(a.field, a.profiles)[0])
	a.field[0].race_form *= 0.5
	check(is_equal_approx(float(Form.ballot_weights(a.field, a.profiles)[0]), weight_before * 0.5), "Hidden form proportionally changes ballot weight")
	var card := Form.card(a.field[0], a.profiles, {str(int(a.field[0].id)): [{"rank": 1}, {"rank": 0}, {"rank": 5}]})
	check(card.recent == "1 · DNF · 5", "Recent card uses newest-first finishes and DNF")

func test_ballot() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 723
	var counts := [0, 0, 0]
	for i in range(20000):
		counts[Form.pick_ballot([1.0, 3.0, 0.0], rng)] += 1
	check(counts[2] == 0, "Inactive horse receives no ballots")
	check(counts[1] > 14500 and counts[1] < 15500, "3:1 weights produce proportional selection")
	check(Form.pick_ballot([0.0, 0.0], rng) == -1, "No active runner handled safely")
	var m = fresh()
	var before: Array = []
	for h in m.field:
		before.append(h.position)
	m.fall_denominator = 1000000000
	m.start_race()
	m.step_race()
	var changed := 0
	for i in range(6):
		if m.field[i].position != before[i]:
			changed += 1
	check(changed <= 1, "Only the ballot winner can move in one loop")
	m.field[0].fallen = true
	check(Form.ballot_weights(m.field, m.profiles)[0] == 0, "Fallen runner excluded from ballot")

func test_history() -> void:
	var m = fresh()
	var ids: Array = []
	for h in m.field:
		ids.append(str(int(h.id)))
	for run in range(7):
		# Reuse this lineup to exercise one horse's bounded racing record.
		m.settled = false
		m.void_race = false
		m.finish_order = [5, 4, 3, 2, 1, 0]
		m.field[0].fallen = false
		m.settle_race()
	check(m.recent_results[ids[0]].size() == 5, "Recent history bounded to last five starts")
	check(int(m.recent_results[ids[0]][0].rank) == 6, "Full Form race records sixth place")
	check(int(m.recent_results[ids[5]][0].rank) == 1, "Winner recorded correctly")
	var history = json_value(m.recent_results)
	m.settle_race()
	check(json_value(m.recent_results) == history, "History settlement idempotent")
	m.settled = false
	m.void_race = true
	m.settle_race()
	check(json_value(m.recent_results) == history, "Void race adds no recent result")
	var form_runs: int = m.total_races
	m.new_game(["ORIGINAL"], 45, Model.ORIGINAL)
	check(m.total_races == 0 and m.stats.is_empty(), "Original records kept separate from Form")
	check(json_value(m.recent_results) == history, "Switching mode preserves Form history")
	m.new_game(["FORM"], 45, Model.FORM)
	check(m.total_races == form_runs, "Returning to Form restores its records")

func test_save_and_migration() -> void:
	var original = fresh(527)
	original.start_race()
	original.advance(3.333)
	check(original.phase == "RACING", "Save fixture still racing")
	var restored = Model.new()
	check(restored.restore(json_value(original.snapshot())), "New Form save accepted")
	check(restored.mode == Model.FORM, "Saved mode restored")
	check(json_value(restored.profiles) == json_value(original.profiles), "Saved traits restored")
	check(finish(original) and finish(restored), "Both resumed Form races complete")
	check(original.finish_order == restored.finish_order, "Resumed weighted ballot order identical")
	check(json_value(original.field) == json_value(restored.field), "Hidden form and surge state survive exact JSON roundtrip")
	check(json_value(original.players) == json_value(restored.players), "Resumed payouts identical")
	check(json_value(original.recent_results) == json_value(restored.recent_results), "Resumed recent history identical")
	check(original.rng.state == restored.rng.state, "Resumed RNG identical")
	var reopened = Model.new()
	reopened.load_persistent(json_value(original.persistent_data()))
	reopened.new_game(["NEW VISIT"], 241, Model.FORM)
	check(json_value(reopened.profiles) == json_value(original.profiles), "Traits survive app restart")
	check(json_value(reopened.recent_results) == json_value(original.recent_results), "Recent results survive app restart")
	var legacy = Model.new()
	legacy.new_game(["OLD SAVE"], 73)
	legacy.start_race()
	legacy.advance(1)
	var old_save: Dictionary = legacy.snapshot()
	old_save.version = 1
	old_save.erase("mode")
	old_save.erase("persistent")
	var migrated = Model.new()
	check(migrated.restore(json_value(old_save)), "Version-1 saved game still accepted")
	check(migrated.mode == Model.ORIGINAL, "Legacy save defaults to Original")
	var old_records := {"stats": {"3": {"runs": 7, "wins": 2, "places": 1, "shows": 0}}, "total_races": 12}
	migrated.load_persistent(old_records)
	check(migrated.total_races == 12 and migrated.stats["3"].runs == 7, "Legacy records preserved under Original")
	migrated.new_game(["FORM"], 14, Model.FORM)
	check(migrated.total_races == 0, "Legacy records do not pollute Form")
	var malformed: Dictionary = original.snapshot()
	malformed.field[0].erase("race_form")
	var target = fresh(72)
	var before = json_value(target.snapshot())
	check(not target.restore(json_value(malformed)), "Malformed Form save rejected")
	check(json_value(target.snapshot()) == before, "Rejected save leaves live model unchanged")

func test_many_races() -> void:
	var falls := 0
	var finishes := 0
	for seed_value in range(80):
		var m = fresh(seed_value)
		for h in m.field:
			check(h.odds >= 2 and h.odds <= 20, "Form quotes within payout range")
		m.start_race()
		check(finish(m), "Weighted race completes within bound")
		var fallen := 0
		for h in m.field:
			if h.fallen:
				fallen += 1
				check(not m.finish_order.has(m.field.find(h)), "Fallen horse never finishes")
		falls += fallen
		finishes += m.finish_order.size()
		check(m.void_race or m.finish_order.size() + fallen == 6, "All live horses finish in Form")
		check(m.players[0].cash >= 0, "Form bankroll nonnegative")
	print("Form simulation: %d finishes, %d falls over 80 seeded races" % [finishes, falls])

func test_late_save() -> void:
	for game_mode in [Model.ORIGINAL, Model.FORM]:
		var original = Model.new()
		original.new_game(["SAVE AFTER A FINISH"], 527, game_mode)
		original.fall_denominator = 1000000000
		original.start_race()
		for tick in range(12000):
			original.step_race()
			if original.finish_order.size() == 1:
				break
		check(original.finish_order.size() == 1 and original.phase == "RACING", "Late save contains an existing finisher")
		var restored = Model.new()
		check(restored.restore(json_value(original.snapshot())), "Late save restores in " + game_mode)
		check(restored.finish_order[0] is int, "Saved finish-order indices normalize to integers")
		check(finish(original) and finish(restored), "Late saved races complete")
		check(original.finish_order == restored.finish_order, "Late save preserves rankings")
		check(json_value(original.players) == json_value(restored.players), "Existing finisher payout survives reload")
		check(json_value(original.stats) == json_value(restored.stats), "Existing finisher statistics survive reload")
