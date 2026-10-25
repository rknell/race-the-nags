extends RefCounted
## Isolated, unpaced races: no players, wagers, or live-race RNG changes.
const Model = preload("res://scripts/race_model.gd")
const RACE_COUNT := 160
var model = Model.new()
var pool: Array = []
var completed := 0
var valid_races := 0

func _init(source: Dictionary, seed_value: int = -1) -> void:
	model.mode = Model.FORM
	model.load_persistent(source)
	if seed_value >= 0:
		model.rng.seed = seed_value
	pool = range(model.stable.size())
	for i in range(pool.size() - 1, 0, -1):
		var j: int = model.rng.randi_range(0, i)
		var swap = pool[i]
		pool[i] = pool[j]
		pool[j] = swap
	pool.resize(maxi(6, int(model.stable.size() * 0.8)))

func run_next() -> void:
	if completed >= RACE_COUNT:
		return
	model.race_number = model.total_races + 1
	model.prepare_field(pool)
	# Background meetings have no betting participants to validate or settle.
	model.phase = "RACING"
	while model.phase == "RACING":
		model.step_race()
	completed += 1
	if not model.void_race:
		valid_races += 1

func persistent_data() -> Dictionary:
	model.history_seeded = true
	return model.persistent_data()
