extends SceneTree

const Model = preload("res://scripts/race_model.gd")
var checks := 0
var failures := 0

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(message)

func same_value(a, b) -> bool:
	# JSON parses all numbers as floats; compare numeric values, not Variant types.
	if (a is int or a is float) and (b is int or b is float):
		# Elapsed clock may lose sub-nanosecond precision through JSON.
		return absf(float(a) - float(b)) <= 1.0e-10
	if a is Array and b is Array:
		if a.size() != b.size():
			return false
		for i in range(a.size()):
			if not same_value(a[i], b[i]):
				return false
		return true
	if a is Dictionary and b is Dictionary:
		if a.size() != b.size():
			return false
		for key in a:
			if not b.has(key) or not same_value(a[key], b[key]):
				return false
		return true
	return a == b

func fresh(seed_value: int = 42):
	var model = Model.new()
	model.new_game(["Alice", "Bob"], seed_value)
	return model

func complete(model, limit: int = 30000) -> bool:
	for tick in range(limit):
		if model.phase != "RACING":
			return model.phase == "RESULTS"
		model.step_race()
	return false

func _initialize() -> void:
	test_field_and_players()
	test_wagers()
	test_returns_and_settlement()
	test_race_and_falls()
	test_snapshot()
	test_batch()
	print("Model tests: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)

func test_field_and_players() -> void:
	var model = fresh()
	check(model.stable.size() == 217, "Public stable must contain 217 new names")
	check(model.players.size() == 2, "Two supplied names create two players")
	check(model.players[0].name == "ALICE", "Names are uppercase")
	for player in model.players:
		check(player.cash == 5000, "Evaluation bankroll is $50")
	model.new_game([], 1)
	check(model.players.size() == 1, "Empty player list supplies one player")
	model.new_game(["a", "b", "c", "d", "e", "f", "g"], 2)
	check(model.players.size() == 6, "At most six players")
	for seed_value in range(30):
		model.new_game(["a"], seed_value)
		check(model.field.size() == 6, "Six runners in each race")
		var ids := {}
		for horse in model.field:
			ids[horse.id] = true
			check(horse.odds >= 2 and horse.odds <= 20, "Odds stay in 2..20")
		check(ids.size() == 6, "A race contains six distinct stable entries")

func test_wagers() -> void:
	var model = fresh()
	check(not model.set_bet(-1, 0, 0, 200), "Negative player rejected")
	check(not model.set_bet(2, 0, 0, 200), "Out of range player rejected")
	check(not model.set_bet(0, -1, 0, 200), "Negative horse rejected")
	check(not model.set_bet(0, 6, 0, 200), "Out of range horse rejected")
	check(not model.set_bet(0, 0, -1, 200), "Negative wager type rejected")
	check(not model.set_bet(0, 0, 3, 200), "Out of range wager type rejected")
	check(not model.set_bet(0, 0, 0, 199), "Below $2 rejected")
	check(not model.set_bet(0, 0, 0, 5001), "Insufficient funds rejected")
	check(model.set_bet(0, 0, 0, 200), "Exactly $2 accepted")
	model.players[0].cash = 200000
	check(not model.set_bet(0, 0, 0, 100001), "Above $1000 rejected")
	check(model.set_bet(0, 0, 0, 100000), "Exactly $1000 accepted")
	check(model.start_race(), "Valid wagers start race")
	check(model.players[0].cash == 100000, "Stake debited on start")
	check(not model.start_race(), "Race cannot start twice")
	check(not model.set_bet(0, 0, 0, 200), "Cannot change bet during race")
	model = fresh()
	model.players[0].cash = 199
	model.players[1].cash = 0
	check(not model.can_play(), "All players below minimum are broke")
	check(not model.start_race(), "All-broke race cannot start")
	model.players[1].cash = 200
	check(model.start_race(), "Solvent player races while broke player sits out")
	check(model.players[0].cash == 199, "Broke spectator is not charged")
	check(model.players[1].cash == 0, "Exactly affordable bet may leave zero")

func test_returns_and_settlement() -> void:
	check(Model.return_amount(2000, 10, 0, 1) == 20000, "WIN returns stake times odds")
	check(Model.return_amount(2000, 10, 0, 2) == 0, "WIN loses in second")
	for rank in [1, 2]:
		check(Model.return_amount(2000, 10, 1, rank, 20) == 5600, "PLACE returns stake plus 20% net odds")
	check(Model.return_amount(2000, 10, 1, 3, 25) == 0, "PLACE loses in third")
	check(Model.return_amount(2000, 10, 1, 2, 25) == 6500, "PLACE upper percentage")
	for rank in [1, 2, 3]:
		check(Model.return_amount(2000, 10, 2, rank, 10) == 3800, "SHOW qualifies all top three")
	check(Model.return_amount(2000, 10, 2, 3, 15) == 4700, "SHOW upper percentage")
	for kind in range(3):
		check(Model.return_amount(200, 2, kind, 0) == 0, "Nonfinisher never qualifies")
		check(Model.return_amount(200, 2, kind, 4) == 0, "Fourth never qualifies")
	check(Model.return_amount(200, 2, 1, 1, 20) == 240, "Low odds PLACE returns stake and profit")
	check(Model.return_amount(200, 2, 2, 3, 10) == 220, "Low odds SHOW returns stake and profit")
	var model = fresh()
	model.field[0].odds = 10
	model.set_bet(0, 0, 1, 2000)
	model.set_bet(1, 3, 0, 2000)
	model.place_percent = 20
	model.start_race()
	model.finish_order = [0, 1, 2]
	model.settle_race()
	check(model.players[0].cash == 8600, "Settlement credits return after stake debit")
	check(model.players[1].cash == 3000, "Losing player retains bankroll minus stake")
	var saved := JSON.stringify(model.snapshot())
	model.settle_race()
	check(JSON.stringify(model.snapshot()) == saved, "Settlement is idempotent including statistics")

func test_race_and_falls() -> void:
	var model = fresh(723)
	model.fall_denominator = 1000000000
	model.set_bet(0, 0, 0, 200)
	model.start_race()
	model.field[0].fallen = true
	check(complete(model), "Race completes with one fallen runner")
	check(model.finish_order.size() == 3, "Normal race resolves three finishers")
	check(not model.finish_order.has(0), "Fallen horse cannot finish or win")
	check(model.results[0]["return"] == 0, "Fallen selected horse loses stake")
	model = fresh(112)
	model.fall_denominator = 1
	model.set_bet(0, 0, 0, 5000)
	model.start_race()
	check(complete(model, 1000), "Guaranteed falls resolve rather than hang")
	var falls := 0
	for horse in model.field:
		if horse.fallen:
			falls += 1
	check(falls == 4 and model.void_race, "Four fallen runners void race")
	check(model.players[0].cash == 5000 and model.players[1].cash == 5000, "Voided race refunds all stakes")

func test_snapshot() -> void:
	var original = fresh(35703)
	original.start_race()
	for i in range(450):
		original.advance(0.011)
	check(original.phase == "RACING", "Roundtrip fixture is midrace")
	var decoded = JSON.parse_string(JSON.stringify(original.snapshot()))
	var restored = Model.new()
	check(restored.restore(decoded), "JSON snapshot restores")
	check(original.rng.state == restored.rng.state, "RNG state survives string/JSON roundtrip exactly")
	check(complete(original) and complete(restored), "Original and restored races finish")
	check(original.finish_order == restored.finish_order, "Restored finish order is identical")
	check(same_value(original.field, restored.field), "Restored movements, falls, and finish times identical")
	check(same_value(original.players, restored.players), "Restored payouts identical")
	check(original.rng.state == restored.rng.state, "RNG advances identically after restore")
	check(same_value(original.stats, restored.stats), "Restored statistics identical")

func test_batch() -> void:
	for seed_value in range(100):
		var model = fresh(seed_value)
		for race_index in range(3):
			if not model.can_play():
				break
			model.automatic_bets()
			check(model.start_race(), "Batch automatic wagers valid")
			check(complete(model), "Batch seed %d race %d finishes within bound" % [seed_value, race_index])
			check(model.void_race or model.finish_order.size() == 3, "Batch race has top three or is void")
			for player in model.players:
				check(player.cash >= 0, "Batch bankroll never negative")
			model.next_race()
