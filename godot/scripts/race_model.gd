extends RefCounted
## All money is integer cents. This model has no scene or display dependencies.
const FormRacing = preload("res://scripts/form_racing.gd")
const ORIGINAL := "original"
const FORM := "form"
# Keep the saved mode id "form" so existing games and records continue to load.
const QUINELLA := 3
const EXACTA := 4
const TRIFECTA := 5
const BOX_TRIFECTA := 6
const BET_LABELS := ["Win", "Place", "Show", "Quinella", "Exacta", "Trifecta", "Box trifecta"]
const BET_HELP := ["Finish first", "Finish in the top two", "Finish in the top three", "Pick the first two, in either order", "Pick first and second, in that order", "Pick first, second and third, in that order", "Pick three horses to fill the top three, in any order"]
const AUTO_RANDOM := "random"
const AUTO_FAVOURITE := "favourite"
const AUTO_RATINGS := "ratings"
const AUTO_SECOND := "second_favourite"
const AUTO_MIDFIELD := "midfield"
const AUTO_OUTSIDE := "outside_chance"
const AUTO_UNDERDOG := "underdog"
const AUTO_SPEED := "speed"
const AUTO_STAMINA := "stamina"
const AUTO_CONSISTENCY := "consistency"
const AUTO_RECENT := "recent"
const AUTO_VALUE := "value"
const AUTO_STRATEGIES := [AUTO_RANDOM, AUTO_FAVOURITE, AUTO_RATINGS, AUTO_SECOND, AUTO_MIDFIELD, AUTO_OUTSIDE, AUTO_UNDERDOG, AUTO_SPEED, AUTO_STAMINA, AUTO_CONSISTENCY, AUTO_RECENT, AUTO_VALUE]
const AUTO_LABELS := ["Random horse", "Favourite", "Form favourite", "Second favourite", "Midfield", "Outside chance", "Underdog", "Fastest runner", "Best stamina", "Most consistent", "Recent form", "Form value"]
const AUTO_FORM_ONLY := [AUTO_RATINGS, AUTO_SPEED, AUTO_STAMINA, AUTO_CONSISTENCY, AUTO_RECENT, AUTO_VALUE]
const AUTO_REMASTERED_ONLY := [AUTO_RATINGS, AUTO_SECOND, AUTO_MIDFIELD, AUTO_OUTSIDE, AUTO_UNDERDOG, AUTO_SPEED, AUTO_STAMINA, AUTO_CONSISTENCY, AUTO_RECENT, AUTO_VALUE]
const AUTO_TOOLTIPS := [
	"Random horse for each player, every race.",
	"Lowest odds in the field.",
	"Strongest public pace and recent results, discounted 2% per consistency point below five.",
	"Second runner when ordered by shortest odds.",
	"Third runner when ordered by shortest odds.",
	"Second-longest odds in the field.",
	"Longest odds in the field.",
	"Highest public speed trait (Remastered only).",
	"Highest public stamina trait (Remastered only).",
	"Highest public consistency trait (Remastered only).",
	"Best recent-results trend; runners without history have a neutral score (Remastered only).",
	"Public rating multiplied by odds: favours stronger runners at longer prices (Remastered only)."
]
const MIN_BET := 200
const MAX_BET := 100000
const DISTANCE := 568.0
const STEP := 0.008
var mode := ORIGINAL
var profiles: Dictionary = {}
var recent_results: Dictionary = {}
var history_seeded := false
var records_by_mode: Dictionary = {ORIGINAL: {"stats": {}, "total_races": 0}, FORM: {"stats": {}, "total_races": 0}}
var rng := RandomNumberGenerator.new()
var stable: Array = []
var players: Array = []
var field: Array = []
var finish_order: Array = []
var results: Array = []
var phase := "BETTING"
var race_number := 1
var elapsed := 0.0
var accumulator := 0.0
var auto_remaining := 0
var auto_stake := 200
var auto_strategy := AUTO_RANDOM
# -1 retains the optional random finish choice; 0/1/2 are Win/Place/Show.
var auto_kind := 0
var stats: Dictionary = {}
var total_races := 0
var settled := false
var fall_denominator := 1200
var place_percent := 20
var show_percent := 10
var void_race := false
var played_races := 0
var bazooka_used := false
var bazooka_target := -1

func _init() -> void:
	rng.randomize()
	var file := FileAccess.open("res://data/horses.json", FileAccess.READ)
	if file:
		var parsed = JSON.parse_string(file.get_as_text())
		if parsed is Array:
			stable = parsed
		elif parsed is Dictionary:
			stable = parsed.get("horses", [])
	if stable.is_empty():
		stable = ["MIDNIGHT EXPRESS", "LUCKY STRIKE", "OLD FAITHFUL", "DUSTY TRAIL", "LONG SHOT", "PHOTO FINISH"]

	profiles = FormRacing.make_profiles(stable)

func new_game(names: Array, seed_value: int = -1, selected_mode: String = ORIGINAL) -> void:
	store_mode_records()
	mode = selected_mode if selected_mode in [ORIGINAL, FORM] else ORIGINAL
	if mode != FORM and auto_strategy in AUTO_REMASTERED_ONLY:
		auto_strategy = AUTO_FAVOURITE
	if mode == ORIGINAL and auto_kind > 2:
		auto_kind = 0
	stats = records_by_mode[mode].stats
	total_races = int(records_by_mode[mode].total_races)
	if seed_value >= 0:
		rng.seed = seed_value
	players.clear()
	for name_value in names.slice(0, 6):
		var clean := str(name_value).strip_edges().to_upper().left(18)
		if not clean.is_empty():
			players.append({"name": clean, "cash": 5000, "horse": 0, "kind": 0, "stake": 200})
	if players.is_empty():
		players.append({"name": "PLAYER 1", "cash": 5000, "horse": 0, "kind": 0, "stake": 200})
	race_number = 1
	auto_remaining = 0
	prepare_field()

func prepare_field(horse_pool: Array = []) -> void:
	phase = "BETTING"
	settled = false
	void_race = false
	bazooka_used = false
	bazooka_target = -1
	fall_denominator = rng.randi_range(1200, 6199)
	place_percent = rng.randi_range(20, 25)
	show_percent = rng.randi_range(10, 15)
	elapsed = 0.0
	accumulator = 0.0
	finish_order.clear()
	results.clear()
	field.clear()
	var choices: Array = range(stable.size()) if horse_pool.is_empty() else horse_pool.duplicate()
	for i in range(6):
		var pick := rng.randi_range(0, choices.size() - 1)
		var horse_id: int = choices.pop_at(pick)
		var value = stable[horse_id]
		var horse_name := str(value.get("name", "HORSE")) if value is Dictionary else str(value)
		field.append({"id": horse_id, "name": horse_name, "odds": rng.randi_range(2, 20), "position": 1.0, "fallen": false, "finished": false, "time": 0.0})
	if mode == FORM:
		FormRacing.prepare(field, profiles, recent_results, rng, race_number)
	for player in players:
		player.stake = mini(int(player.stake), mini(MAX_BET, int(player.cash)))

func set_bet(player_id: int, horse_id: int, kind: int, stake: int, runners: Array = []) -> bool:
	if phase != "BETTING" or player_id < 0 or player_id >= players.size():
		return false
	var p: Dictionary = players[player_id]
	if horse_id < 0 or horse_id >= 6 or kind < 0 or kind > (BOX_TRIFECTA if mode == FORM else 2) or stake < MIN_BET or stake > mini(int(p.cash), MAX_BET):
		return false
	if kind > 2 and (not valid_runners(kind, runners) or int(runners[0]) != horse_id):
		return false
	if kind > 2:
		p["runners"] = runners.duplicate()
	else:
		p.erase("runners")
	p.horse = horse_id
	p.kind = kind
	p.stake = stake
	return true

func start_race() -> bool:
	if phase != "BETTING":
		return false
	var active := 0
	for p in players:
		if int(p.cash) < MIN_BET:
			continue
		if int(p.kind) > 2 and (mode != FORM or not valid_runners(int(p.kind), p.get("runners", []))):
			return false
		if int(p.stake) < MIN_BET or int(p.stake) > mini(int(p.cash), MAX_BET):
			return false
		active += 1
	if active == 0:
		return false
	for p in players:
		if int(p.cash) >= MIN_BET:
			p.cash = int(p.cash) - int(p.stake)
			p["racing"] = true
		else:
			p["racing"] = false
	phase = "RACING"
	return true

func bazooka_available() -> bool:
	return played_races >= 3 and phase == "RACING" and not bazooka_used

func fire_bazooka() -> int:
	if not bazooka_available():
		return -1
	var targets: Array = range(field.size()).filter(func(i): return not field[i].fallen and not field[i].finished)
	if targets.is_empty():
		return -1
	# Uniform among surviving runners: your own ticket gets no protection.
	bazooka_target = int(targets[rng.randi_range(0, targets.size() - 1)])
	bazooka_used = true
	field[bazooka_target].fallen = true
	field[bazooka_target]["blasted"] = true
	var fallen_count := 0
	var active := 0
	for horse in field:
		if horse.fallen:
			fallen_count += 1
		elif not horse.finished:
			active += 1
	if fallen_count >= 4:
		void_race = true
		settle_race()
	elif active == 0:
		settle_race()
	return bazooka_target

func advance(delta: float) -> bool:
	if phase != "RACING":
		return false
	accumulator += delta
	while accumulator >= STEP and phase == "RACING":
		accumulator -= STEP
		step_race()
	return phase == "RESULTS"

func step_race() -> void:
	if mode == FORM:
		step_form_race()
		return
	# Recovered DOS loop: choose one runner, then a 0..5 pixel advance.
	# Clock pacing and RNG implementation are native Godot adaptations.
	elapsed += STEP
	var i := rng.randi_range(0, 5)
	var h: Dictionary = field[i]
	if h.fallen or h.finished:
		return
	var movement := rng.randi_range(0, 5)
	if int(h.odds) > 10 and rng.randi_range(0, 11) == 0:
		movement = 1
	if int(h.odds) > 15 and rng.randi_range(0, 8) == 0:
		movement = 0
	if rng.randi_range(0, fall_denominator - 1) == 0:
		h.fallen = true
		var fallen_count := 0
		for runner in field:
			if runner.fallen:
				fallen_count += 1
		if fallen_count >= 4:
			void_race = true
			settle_race()
		return
	h.position = float(h.position) + movement
	if float(h.position) > DISTANCE:
		h.finished = true
		h.time = elapsed
		finish_order.append(i)
		if finish_order.size() == 3:
			settle_race()

func step_form_race() -> void:
	elapsed += STEP
	for horse in field:
		if horse.fallen or horse.finished:
			continue
		if elapsed >= float(horse.surge_until):
			var traits: Dictionary = profiles[str(int(horse.id))]
			var spread := 0.12 + 0.035 * (5 - int(traits.consistency))
			horse.surge = rng.randf_range(1.0 - spread, 1.0 + spread)
			horse.surge_until = elapsed + rng.randf_range(0.7, 1.6)
	var selected := FormRacing.pick_ballot(FormRacing.ballot_weights(field, profiles), rng)
	if selected < 0:
		settle_race()
		return
	var horse: Dictionary = field[selected]
	if rng.randi_range(0, fall_denominator - 1) == 0:
		horse.fallen = true
		var fallen_count := 0
		for runner in field:
			if runner.fallen:
				fallen_count += 1
		if fallen_count >= 4:
			void_race = true
			settle_race()
		return
	horse.position = float(horse.position) + rng.randi_range(0, 5)
	if float(horse.position) > DISTANCE:
		horse.finished = true
		horse.time = elapsed
		finish_order.append(selected)
	var active := false
	for runner in field:
		if not runner.fallen and not runner.finished:
			active = true
	if not active:
		settle_race()

func racing_card(lane: int) -> Dictionary:
	if mode != FORM or lane < 0 or lane >= field.size():
		return {}
	return FormRacing.card(field[lane], profiles, recent_results)

func mode_name() -> String:
	return "Remastered" if mode == FORM else "Original"

func store_mode_records() -> void:
	records_by_mode[mode] = {"stats": stats.duplicate(true), "total_races": total_races}

func persistent_data() -> Dictionary:
	store_mode_records()
	return {"version": 2, "profiles": profiles.duplicate(true), "recent_results": recent_results.duplicate(true), "records_by_mode": records_by_mode.duplicate(true), "history_seeded": history_seeded, "played_races": played_races}

func load_persistent(data: Dictionary) -> void:
	history_seeded = bool(data.get("history_seeded", false))
	played_races = maxi(played_races, int(data.get("played_races", 0)))
	# Old records belong to Original mode. Traits use a deterministic private RNG
	# and are also stored, so reopening the app never rerolls the stable.
	var saved_profiles = data.get("profiles", {})
	for key in profiles:
		var candidate = saved_profiles.get(key, {}) if saved_profiles is Dictionary else {}
		if candidate is Dictionary and candidate.has_all(["speed", "stamina", "consistency"]):
			var valid := true
			for trait_key in ["speed", "stamina", "consistency"]:
				if not (candidate[trait_key] is int or candidate[trait_key] is float) or float(candidate[trait_key]) < 1 or float(candidate[trait_key]) > 5:
					valid = false
			if valid:
				profiles[key] = candidate.duplicate(true)
	var saved_records = data.get("records_by_mode", {})
	if saved_records is Dictionary:
		for game_mode in [ORIGINAL, FORM]:
			var record = saved_records.get(game_mode, {})
			if record is Dictionary and record.get("stats") is Dictionary:
				records_by_mode[game_mode] = {"stats": record.stats.duplicate(true), "total_races": int(record.get("total_races", 0))}
	if not data.has("records_by_mode") and data.get("stats") is Dictionary:
		records_by_mode[ORIGINAL] = {"stats": data.stats.duplicate(true), "total_races": int(data.get("total_races", 0))}
	var saved_recent = data.get("recent_results", {})
	if saved_recent is Dictionary:
		recent_results.clear()
		for key in profiles:
			if not saved_recent.has(key):
				continue
			var history = saved_recent.get(key, [])
			if not history is Array:
				continue
			var valid_history: Array = []
			for result in history.slice(0, FormRacing.RECENT_LIMIT):
				if result is Dictionary and (result.get("rank") is int or result.get("rank") is float) and int(result.rank) >= 0 and int(result.rank) <= 6:
					valid_history.append(result.duplicate(true))
			recent_results[key] = valid_history
	stats = records_by_mode[mode].stats
	total_races = int(records_by_mode[mode].total_races)

static func return_amount(stake: int, odds: int, kind: int, rank: int, percent: int = 20) -> int:
	if rank < 1 or rank > kind + 1:
		return 0
	if kind == 0:
		return stake * odds
	# Manual p13: PLACE/SHOW pay a fraction of (stake*odds - stake).
	return stake + int(round(float(stake * (odds - 1) * percent) / 100.0))

static func runner_count(kind: int) -> int:
	return 3 if kind in [TRIFECTA, BOX_TRIFECTA] else (2 if kind in [QUINELLA, EXACTA] else 1)

static func valid_runners(kind: int, runners: Array) -> bool:
	if runners.size() != runner_count(kind):
		return false
	var seen := {}
	for runner in runners:
		if not (runner is int or runner is float) or float(runner) != floor(float(runner)) or int(runner) < 0 or int(runner) >= 6 or seen.has(int(runner)):
			return false
		seen[int(runner)] = true
	return true

func ticket_runners(player: Dictionary) -> Array:
	var runners: Array = player.get("runners", [int(player.horse)]) if int(player.kind) > 2 else [int(player.horse)]
	return runners.map(func(runner): return int(runner))

func exotic_quote(stake: int, kind: int, runners: Array) -> int:
	if mode != FORM or kind <= 2 or not valid_runners(kind, runners):
		return 0
	# Transparent arcade quotes, not real-world pool dividends. Stake is the
	# whole ticket cost, including every order covered by an unordered bet.
	var product := 1
	for runner in runners:
		product *= int(field[int(runner)].odds)
	var combinations := 2 if kind == QUINELLA else (6 if kind == BOX_TRIFECTA else 1)
	return int(round(float(stake * product) / combinations))

func exotic_wins(kind: int, runners: Array) -> bool:
	if not valid_runners(kind, runners) or finish_order.size() < runners.size():
		return false
	var actual: Array = finish_order.slice(0, runners.size())
	var chosen := []
	for runner in runners:
		chosen.append(int(runner))
	if kind in [QUINELLA, BOX_TRIFECTA]:
		actual.sort()
		chosen.sort()
	return actual == chosen

func settle_race() -> void:
	if settled:
		return
	settled = true
	if not players.is_empty():
		played_races += 1
	phase = "RESULTS"
	if not void_race:
		total_races += 1
	for i in range(0 if void_race else field.size()):
		var h: Dictionary = field[i]
		var key := str(int(h.id))
		var record: Dictionary = stats.get(key, {"runs": 0, "wins": 0, "places": 0, "shows": 0})
		record.runs = int(record.runs) + 1
		var rank := finish_order.find(i) + 1
		if rank > 0 and rank <= 3:
			var stat_key: String = ["wins", "places", "shows"][rank - 1]
			record[stat_key] = int(record[stat_key]) + 1
		stats[key] = record
		if mode == FORM:
			var recent: Array = recent_results.get(key, []).duplicate(true)
			recent.push_front({"rank": rank, "race": race_number})
			recent_results[key] = recent.slice(0, FormRacing.RECENT_LIMIT)
	results.clear()
	for p in players:
		if not p.get("racing", false):
			results.append({"name": p.name, "return": 0, "net": 0, "text": "Broke — sitting out"})
			continue
		var h: Dictionary = field[int(p.horse)]
		var rank := finish_order.find(int(p.horse)) + 1
		var percent := place_percent if int(p.kind) == 1 else show_percent
		var paid := int(p.stake) if void_race else return_amount(int(p.stake), int(h.odds), int(p.kind), rank, percent)
		if int(p.kind) > 2 and not void_race:
			paid = exotic_quote(int(p.stake), int(p.kind), ticket_runners(p)) if exotic_wins(int(p.kind), ticket_runners(p)) else 0
		p.cash = int(p.cash) + paid
		var outcome := "Winning ticket" if paid > 0 else "Ticket missed"
		results.append({"name": p.name, "return": paid, "net": paid - int(p.stake), "text": "Race void — refunded" if void_race else (outcome if int(p.kind) > 2 else ("Bazooka!" if h.get("blasted", false) else "Jockey fell!" if h.fallen else ("Finished #%d" % rank if rank > 0 else "Unplaced")))})

func next_race() -> void:
	if phase != "RESULTS":
		return
	race_number += 1
	prepare_field()

func automatic_horse(excluded: Array = []) -> int:
	var available: Array = range(field.size()).filter(func(i): return not i in excluded)
	if auto_strategy == AUTO_RANDOM:
		return available[rng.randi_range(0, available.size() - 1)]
	if auto_strategy in [AUTO_FAVOURITE, AUTO_SECOND, AUTO_MIDFIELD, AUTO_OUTSIDE, AUTO_UNDERDOG] or mode != FORM:
		var runners: Array = available.duplicate()
		runners.sort_custom(func(a, b):
			return int(field[a].odds) < int(field[b].odds) if field[a].odds != field[b].odds else a < b)
		var rank := 0
		match auto_strategy:
			AUTO_SECOND: rank = mini(1, runners.size() - 1)
			AUTO_MIDFIELD: rank = mini(2, runners.size() - 1)
			AUTO_OUTSIDE: rank = maxi(0, runners.size() - 2)
			AUTO_UNDERDOG: rank = runners.size() - 1
		# Highest-odds selectors also break tied prices by lowest runner number.
		var odds := int(field[runners[rank]].odds)
		for i in available:
			if int(field[i].odds) == odds:
				return i
	var best := 0
	var best_score := -INF
	for i in available:
		var key := str(int(field[i].id))
		var traits: Dictionary = profiles[key]
		var recent: Array = recent_results.get(key, [])
		# Only public information; never inspect race_form or surge.
		var score := FormRacing.public_rating(traits, recent) * (1.0 - 0.02 * (5 - int(traits.consistency)))
		match auto_strategy:
			AUTO_SPEED: score = float(traits.speed)
			AUTO_STAMINA: score = float(traits.stamina)
			AUTO_CONSISTENCY: score = float(traits.consistency)
			AUTO_RECENT: score = FormRacing.recent_factor(recent)
			AUTO_VALUE: score *= float(field[i].odds)
		if score > best_score:
			best = i
			best_score = score
	return best

func automatic_bets() -> void:
	if phase != "BETTING":
		return
	for i in range(players.size()):
		var cash := int(players[i].cash)
		if cash >= MIN_BET:
			var desired := auto_stake if auto_stake > 0 else maxi(MIN_BET, int(round(float(cash) / 1000.0)) * 100)
			var horse := automatic_horse()
			var kind := rng.randi_range(0, 2) if auto_kind == -1 else auto_kind
			if mode == ORIGINAL and kind > 2:
				kind = 0
			var runners := [horse]
			while runners.size() < runner_count(kind):
				runners.append(automatic_horse(runners))
			set_bet(i, horse, kind, mini(desired, mini(cash, MAX_BET)), runners)

func can_play() -> bool:
	for p in players:
		if int(p.cash) >= MIN_BET:
			return true
	return false

func snapshot() -> Dictionary:
	return {"version": 2, "mode": mode, "persistent": persistent_data(), "players": players.duplicate(true), "field": field.duplicate(true), "finish_order": finish_order.duplicate(), "results": results.duplicate(true), "phase": phase, "race_number": race_number, "elapsed": elapsed, "accumulator": accumulator, "stats": stats.duplicate(true), "total_races": total_races, "settled": settled, "auto_remaining": auto_remaining, "auto_stake": auto_stake, "auto_strategy": auto_strategy, "auto_kind": auto_kind, "fall_denominator": fall_denominator, "place_percent": place_percent, "show_percent": show_percent, "void_race": void_race, "bazooka_used": bazooka_used, "bazooka_target": bazooka_target, "rng_state": str(rng.state)}

func restore(data: Dictionary) -> bool:
	if not int(data.get("version", 0)) in [1, 2] or not data.get("phase", "") in ["BETTING", "RACING", "RESULTS"]:
		return false
	for key in ["players", "field", "finish_order", "results"]:
		if not data.get(key) is Array:
			return false
	if data.players.size() > 6 or not data.get("stats") is Dictionary:
		return false
	for key in ["race_number", "elapsed", "accumulator", "total_races"]:
		if not (data.get(key) is float or data.get(key) is int):
			return false
	if not data.get("rng_state") is String or not data.rng_state.is_valid_int():
		return false
	for player in data.players:
		if not player is Dictionary or not player.get("name") is String:
			return false
		for key in ["cash", "horse", "kind", "stake"]:
			if not (player.get(key) is float or player.get(key) is int):
				return false
		if player.cash < 0 or player.horse < 0 or player.horse > 5 or player.kind < 0 or player.kind > (BOX_TRIFECTA if data.get("mode", ORIGINAL) == FORM else 2):
			return false
		if int(player.kind) > 2 and (not player.get("runners") is Array or not valid_runners(int(player.kind), player.runners) or int(player.runners[0]) != int(player.horse)):
			return false
	for horse in data.field:
		if not horse is Dictionary or not horse.get("name") is String:
			return false
		for key in ["id", "odds", "position", "time"]:
			if not (horse.get(key) is float or horse.get(key) is int):
				return false
		if not horse.get("fallen") is bool or not horse.get("finished") is bool:
			return false
	for horse_id in data.finish_order:
		if not (horse_id is int or horse_id is float) or horse_id < 0 or horse_id > 5:
			return false
	if data.players.is_empty() or data.field.size() != 6:
		return false
	var saved_mode := str(data.get("mode", ORIGINAL))
	if not saved_mode in [ORIGINAL, FORM]:
		return false
	if saved_mode == FORM:
		if data.get("version") != 2 or not data.get("persistent") is Dictionary:
			return false
		for horse in data.field:
			for key in ["race_form", "recent_factor", "surge", "surge_until"]:
				if not (horse.get(key) is int or horse.get(key) is float) or not is_finite(float(horse[key])) or float(horse[key]) <= 0:
					return false
			if int(horse.id) < 0 or int(horse.id) >= stable.size():
				return false
	mode = saved_mode
	if data.get("persistent") is Dictionary:
		load_persistent(data.persistent)
	players = data.players
	field = data.field
	finish_order = []
	for horse_id in data.finish_order:
		finish_order.append(int(horse_id))
	results = data.results
	phase = data.phase
	race_number = int(data.race_number)
	elapsed = float(data.elapsed)
	accumulator = float(data.accumulator)
	stats = data.stats
	total_races = int(data.total_races)
	settled = bool(data.settled)
	auto_remaining = int(data.get("auto_remaining", 0))
	auto_stake = int(data.get("auto_stake", 200))
	auto_strategy = str(data.get("auto_strategy", AUTO_RANDOM))
	if not auto_strategy in AUTO_STRATEGIES:
		auto_strategy = AUTO_RANDOM
	if mode != FORM and auto_strategy in AUTO_REMASTERED_ONLY:
		auto_strategy = AUTO_FAVOURITE
	var saved_kind = data.get("auto_kind", -1 if auto_strategy == AUTO_RANDOM else 0)
	auto_kind = int(saved_kind) if (saved_kind is int or saved_kind is float) and float(saved_kind) == floor(float(saved_kind)) and int(saved_kind) >= -1 and int(saved_kind) <= (BOX_TRIFECTA if mode == FORM else 2) else 0
	fall_denominator = int(data.get("fall_denominator", 1200))
	place_percent = int(data.get("place_percent", 20))
	show_percent = int(data.get("show_percent", 10))
	void_race = bool(data.get("void_race", false))
	bazooka_used = bool(data.get("bazooka_used", false))
	bazooka_target = int(data.get("bazooka_target", -1))
	store_mode_records()
	rng.state = int(data.rng_state)
	return true
