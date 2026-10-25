extends RefCounted
## New game design, separate from recovered DOS rules.
const FORECAST_SAMPLES := 768
const RECENT_LIMIT := 5

static func make_profiles(stable: Array) -> Dictionary:
	var profiles := {}
	for i in range(stable.size()):
		var generator := RandomNumberGenerator.new()
		# A private generator leaves the Original mode's random stream untouched.
		generator.seed = ("nags-traits-v1:%s" % str(stable[i])).hash()
		profiles[str(i)] = {"speed": generator.randi_range(1, 5), "stamina": generator.randi_range(1, 5), "consistency": generator.randi_range(1, 5)}
	return profiles

static func form_spread(traits: Dictionary) -> float:
	return 0.08 + 0.035 * (5 - int(traits.consistency))

static func recent_factor(recent: Array) -> float:
	# Small public trend; underlying traits still dominate expected performance.
	var trend := 0.0
	var count := 0
	for result in recent:
		var rank := int(result.rank)
		trend += (3.5 - rank) / 2.5 if rank > 0 else -1.0
		count += 1
	return 1.0 + (0.035 * trend / count if count > 0 else 0.0)

static func pace(traits: Dictionary, progress: float) -> float:
	var speed := 0.85 + 0.09 * int(traits.speed)
	var late_pace := 0.78 + 0.095 * int(traits.stamina)
	return speed * lerpf(1.16, late_pace, clampf(progress, 0.0, 1.0))

static func public_rating(traits: Dictionary, recent: Array) -> float:
	# Harmonic mean approximates the time to cover the course at changing pace.
	var time_cost := 0.0
	for i in range(8):
		time_cost += 1.0 / pace(traits, (i + 0.5) / 8.0)
	return 8.0 / time_cost * recent_factor(recent)

static func quote_odds(field: Array, profiles: Dictionary, recent_results: Dictionary, quote_seed: int) -> Array:
	# The bookmaker NEVER reads race_form, surge or the race RNG. Its forecast
	# samples possible form from public traits, rather than revealing today's roll.
	var market := RandomNumberGenerator.new()
	market.seed = quote_seed
	var wins: Array = [0, 0, 0, 0, 0, 0]
	var ratings: Array = []
	var spreads: Array = []
	for horse in field:
		var key := str(int(horse.id))
		var traits: Dictionary = profiles[key]
		ratings.append(public_rating(traits, recent_results.get(key, [])))
		spreads.append(form_spread(traits))
	for sample_index in range(FORECAST_SAMPLES):
		var best := -INF
		var winner := 0
		for i in range(field.size()):
			var rating := float(ratings[i])
			var possible_form := exp(market.randfn(0.0, float(spreads[i])))
			var ballot_noise := exp(market.randfn(0.0, 0.065))
			var score := rating * possible_form * ballot_noise
			if score > best:
				best = score
				winner = i
		wins[winner] += 1
	var odds: Array = []
	for count in wins:
		var probability := float(count + 1) / (FORECAST_SAMPLES + field.size())
		odds.append(clampi(int(round(0.90 / probability)), 2, 20))
	return odds

static func prepare(field: Array, profiles: Dictionary, recent_results: Dictionary, rng: RandomNumberGenerator, race_number: int) -> void:
	var quote_key := "race:%d" % race_number
	for horse in field:
		quote_key += ":%d" % int(horse.id)
	var odds := quote_odds(field, profiles, recent_results, quote_key.hash())
	for i in range(field.size()):
		var horse: Dictionary = field[i]
		var key := str(int(horse.id))
		var traits: Dictionary = profiles[key]
		horse.odds = odds[i]
		horse["race_form"] = clampf(exp(rng.randfn(0.0, form_spread(traits))), 0.55, 1.55)
		horse["recent_factor"] = recent_factor(recent_results.get(key, []))
		horse["surge"] = 1.0
		horse["surge_until"] = rng.randf_range(0.6, 1.4)

static func ballot_weights(field: Array, profiles: Dictionary) -> Array:
	var weights: Array = []
	for horse in field:
		if horse.fallen or horse.finished:
			weights.append(0.0)
			continue
		var traits: Dictionary = profiles[str(int(horse.id))]
		weights.append(pace(traits, float(horse.position) / 568.0) * float(horse.race_form) * float(horse.recent_factor) * float(horse.surge))
	return weights

static func pick_ballot(weights: Array, rng: RandomNumberGenerator) -> int:
	var total := 0.0
	for weight in weights:
		total += float(weight)
	if total <= 0.0:
		return -1
	var ballot := rng.randf() * total
	var last_active := -1
	for i in range(weights.size()):
		if float(weights[i]) <= 0:
			continue
		last_active = i
		ballot -= float(weights[i])
		if ballot < 0:
			return i
	return last_active

static func style(traits: Dictionary) -> String:
	if int(traits.speed) >= int(traits.stamina) + 2:
		return "Fast starter"
	if int(traits.stamina) >= int(traits.speed) + 2:
		return "Strong finisher"
	return "All-rounder"

static func recent_text(recent: Array) -> String:
	if recent.is_empty():
		return "No starts yet"
	var finishes := PackedStringArray()
	for result in recent:
		finishes.append(str(int(result.rank)) if int(result.rank) > 0 else "DNF")
	return " · ".join(finishes)

static func card(horse: Dictionary, profiles: Dictionary, recent_results: Dictionary) -> Dictionary:
	var key := str(int(horse.id))
	var traits: Dictionary = profiles[key]
	# Explicit public projection: private race form never leaves the model here.
	return {"name": str(horse.name), "speed": int(traits.speed), "stamina": int(traits.stamina), "consistency": int(traits.consistency), "style": style(traits), "recent": recent_text(recent_results.get(key, []))}
