extends Control
const Model = preload("res://scripts/race_model.gd")
const Track = preload("res://scripts/track.gd")
const Artwork = preload("res://scripts/artwork.gd")
const HistorySimulation = preload("res://scripts/history_simulation.gd")
const ARROW_RIGHT = preload("res://assets/public/ui/arrow-right.svg")
const ARROW_UP_RIGHT = preload("res://assets/public/ui/arrow-up-right.svg")
const CREAM := Color("f1ead7")
const MUTED := Color("9eb7a7")
const GOLD := Color("e6c278")
var model = Model.new()
var body: Control
var track: Control
var names: Array[LineEdit] = []
var mode_choice: OptionButton
var mode_description: Label
var history_button: Button
var graphics_choice: OptionButton
var title_portrait: TextureRect
var graphics_mode := Artwork.CLASSIC
var preferred_game_mode := Model.ORIGINAL
var settings_path := "user://nags-settings.cfg"
var remembered_names: Array = []
var recent_labels: Array[Label] = []
var bet_rows: Array = []
var card_labels: Array[Label] = []
var balance_labels: Array[Label] = []
var status_label: Label
var phase_label: Label
var primary_button: Button
var notice: Label
var dialog_layer: Control
var in_game := false
const GAME_OVER_SECONDS := 12.0
var game_over_active := false
var game_over_remaining := 0.0
var game_over_countdown: Label
var sound_on := true
var audio: AudioStreamPlayer
var fame: Array = []
var million: Array = []
var auto_strategy_choice: OptionButton
var auto_kind_choice: OptionButton
var ticket_choices: Array[OptionButton] = []
var ticket_apply: Button
var ticket_preview: Label
var auto_count: SpinBox
var auto_amount: SpinBox
var auto_button: Button
var results_auto_button: Button
var auto_run_serial := 0
var audio_timer := 0.0
var save_path := "user://nags-save.json"
var history_path := "user://nags-records.json"

func _ready() -> void:
	get_tree().auto_accept_quit = false
	var custom := Theme.new()
	custom.default_font_size = 16
	custom.set_color("font_color", "Label", CREAM)
	custom.set_color("font_color", "Button", CREAM)
	custom.set_color("font_hover_color", "Button", GOLD)
	custom.set_color("icon_normal_color", "Button", CREAM)
	custom.set_color("icon_hover_color", "Button", GOLD)
	custom.set_stylebox("normal", "Button", box(Color("23473b"), 6, Color("416554")))
	custom.set_stylebox("hover", "Button", box(Color("355e49"), 6, GOLD))
	custom.set_stylebox("pressed", "Button", box(Color("43674b"), 6, GOLD))
	custom.set_stylebox("disabled", "Button", box(Color("182c26"), 6))
	custom.set_stylebox("normal", "LineEdit", box(Color("102a23"), 4, Color("426452")))
	custom.set_color("font_color", "LineEdit", CREAM)
	custom.set_color("font_color", "OptionButton", CREAM)
	theme = custom
	setup_audio()
	load_history()
	var settings := ConfigFile.new()
	if settings.load(settings_path) == OK:
		graphics_mode = maxi(Artwork.CLASSIC, Artwork.MODE_KEYS.find(settings.get_value("graphics", "mode", "classic")))
		var saved_mode = settings.get_value("game", "mode", Model.ORIGINAL)
		preferred_game_mode = Model.FORM if saved_mode == Model.FORM else Model.ORIGINAL
		var saved_sound = settings.get_value("audio", "enabled", true)
		sound_on = saved_sound if saved_sound is bool else true
	load_player_names()
	show_title()

func save_preference(section: String, key: String, value: Variant) -> void:
	var settings := ConfigFile.new()
	settings.load(settings_path)
	settings.set_value(section, key, value)
	settings.save(settings_path)

func auto_preference(key: String, fallback: Variant) -> Variant:
	var settings := ConfigFile.new()
	settings.load(settings_path)
	return settings.get_value("auto_" + model.mode, key, fallback)

func auto_integer_preference(key: String, fallback: int, minimum: int, maximum: int) -> int:
	var value = auto_preference(key, fallback)
	return clampi(value, minimum, maximum) if value is int else fallback

func load_auto_preferences() -> void:
	var strategy = auto_preference("strategy", Model.AUTO_RANDOM)
	model.auto_strategy = strategy if strategy in Model.AUTO_STRATEGIES else Model.AUTO_RANDOM
	if model.mode == Model.ORIGINAL and model.auto_strategy in Model.AUTO_REMASTERED_ONLY:
		model.auto_strategy = Model.AUTO_FAVOURITE
	model.auto_kind = auto_integer_preference("kind", 0, -1, Model.BOX_TRIFECTA if model.mode == Model.FORM else 2)
	model.auto_stake = auto_integer_preference("stake", 200, 0, Model.MAX_BET)

func load_player_names() -> void:
	var settings := ConfigFile.new()
	settings.load(settings_path)
	var saved_names = settings.get_value("players", "names") if settings.has_section_key("players", "names") else null
	# Older versions only kept player names inside the saved game.
	if saved_names == null and FileAccess.file_exists(save_path):
		var data = JSON.parse_string(FileAccess.get_file_as_string(save_path))
		if data is Dictionary and data.get("players") is Array:
			saved_names = []
			for player in data.players.slice(0, 6):
				if player is Dictionary and player.get("name") is String:
					saved_names.append(player.name)
	remembered_names.clear()
	if saved_names is Array:
		for value in saved_names.slice(0, 6):
			remembered_names.append(value.left(18) if value is String else "")

func remember_player_names(values: Array) -> void:
	remembered_names = values.duplicate()
	var settings := ConfigFile.new()
	settings.load(settings_path)
	settings.set_value("players", "names", remembered_names)
	settings.save(settings_path)

func remember_name_entries() -> void:
	var values: Array = []
	for edit in names:
		values.append(edit.text)
	remember_player_names(values)

func box(color: Color, radius: int = 8, border: Color = Color.TRANSPARENT) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = color
	s.set_corner_radius_all(radius)
	s.border_color = border
	s.set_border_width_all(1 if border.a > 0 else 0)
	return s

func panel(parent: Node, rect: Rect2, color: Color = Color("17362c")) -> Panel:
	var p := Panel.new()
	p.position = rect.position
	p.size = rect.size
	p.add_theme_stylebox_override("panel", box(color, 10, Color("345444")))
	parent.add_child(p)
	return p

func label_at(parent: Node, text_value: String, pos: Vector2, font_size: int = 16, color: Color = CREAM) -> Label:
	var l := Label.new()
	l.text = text_value
	l.position = pos
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	parent.add_child(l)
	return l

func button_at(parent: Node, text_value: String, rect: Rect2, callback: Callable, icon: Texture2D = null) -> Button:
	var b := Button.new()
	b.text = text_value
	b.icon = icon
	b.icon_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	b.position = rect.position
	b.size = rect.size
	b.pressed.connect(callback)
	parent.add_child(b)
	if icon != null:
		for state in ["normal", "hover", "pressed", "disabled", "hover_pressed"]:
			var style: StyleBox = b.get_theme_stylebox(state).duplicate()
			style.content_margin_left = 16
			style.content_margin_right = 16
			b.add_theme_stylebox_override(state, style)
	return b

func reset_body() -> void:
	if body:
		remove_child(body)
		body.queue_free()
	body = Control.new()
	body.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(body)
	dialog_layer = null
	title_portrait = null
	track = null
	bet_rows.clear()
	balance_labels.clear()
	card_labels.clear()
	recent_labels.clear()

func show_title() -> void:
	in_game = false
	game_over_active = false
	audio.stop()
	reset_body()
	label_at(body, "INDEPENDENT RECREATION  /  GODOT", Vector2(66, 48), 14, GOLD)
	label_at(body, "RACE THE\nNAGS", Vector2(60, 95), 86)
	label_at(body, "A day at the races. A pocketful of possibilities.", Vector2(66, 320), 20, MUTED)
	label_at(body, "Six horses. Up to six players. $50 to make your fortune.\nChoose your rules and your look, then head to the track.", Vector2(66, 365), 17, MUTED)
	title_portrait = TextureRect.new()
	title_portrait.position = Vector2(410, 548)
	title_portrait.size = Vector2(168, 168)
	title_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	title_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	body.add_child(title_portrait)
	update_portrait()
	label_at(body, "GRAPHICS", Vector2(66, 542), 14, GOLD)
	add_graphics_choice(Vector2(66, 570), Vector2(310, 44))
	mode_choice = OptionButton.new()
	mode_choice.position = Vector2(66, 430)
	mode_choice.size = Vector2(508, 44)
	mode_choice.add_item("Original — recovered DOS rules")
	mode_choice.add_item("Remastered — form & extra bets")
	mode_choice.select(1 if preferred_game_mode == Model.FORM else 0)
	body.add_child(mode_choice)
	mode_description = label_at(body, "", Vector2(66, 486), 14, MUTED)
	mode_choice.item_selected.connect(set_game_mode)
	update_mode_description()
	history_button = button_at(body, "BUILD RECENT FORM", Rect2(66, 640, 310, 42), show_history_simulation)
	history_button.tooltip_text = "Run 160 quick Remastered races for most of the stable, leaving some newcomers. No bets or bankroll changes."
	update_history_button()
	var p := panel(body, Rect2(680, 85, 528, 636))
	label_at(p, "MEET YOUR FELLOW PUNTERS", Vector2(30, 26), 21, GOLD)
	label_at(p, "Names are remembered. Leave unused places empty.", Vector2(30, 66), 16, MUTED)
	names.clear()
	for i in range(6):
		label_at(p, "%02d" % (i + 1), Vector2(31, 117 + i * 54), 18, GOLD)
		var edit := LineEdit.new()
		edit.position = Vector2(76, 110 + i * 54)
		edit.size = Vector2(416, 40)
		edit.placeholder_text = "PLAYER %d" % (i + 1) if i == 0 else "Optional player"
		edit.max_length = 18
		edit.text = str(remembered_names[i]) if i < remembered_names.size() else ""
		edit.text_changed.connect(func(_text): remember_name_entries())
		p.add_child(edit)
		names.append(edit)
	button_at(p, "HEAD TO THE TRACK", Rect2(30, 451, 464, 48), start_new, ARROW_RIGHT)
	var resume := button_at(p, "CONTINUE SAVED GAME", Rect2(30, 513, 464, 42), load_game)
	resume.disabled = not FileAccess.file_exists(save_path)
	button_at(p, "HOW TO PLAY", Rect2(30, 570, 225, 38), show_help)
	button_at(p, "HALL OF FAME", Rect2(269, 570, 225, 38), show_fame)
	label_at(body, "Game & classic art: Dick Olsen / Olsen Outdoors, 1992  •  Free tribute  •  Play money", Vector2(66, 751), 14, MUTED)
	names[0].grab_focus()

func set_game_mode(index: int) -> void:
	preferred_game_mode = Model.FORM if index == 1 else Model.ORIGINAL
	var settings := ConfigFile.new()
	settings.load(settings_path)
	settings.set_value("game", "mode", preferred_game_mode)
	settings.save(settings_path)
	update_mode_description()
	update_history_button()

func update_history_button() -> void:
	if is_instance_valid(history_button):
		history_button.visible = mode_choice.selected == 1
		history_button.disabled = model.history_seeded
		history_button.text = "RECENT FORM ALREADY BUILT" if model.history_seeded else "BUILD RECENT FORM"

func show_history_simulation() -> void:
	if in_game or mode_choice.selected != 1 or model.history_seeded:
		return
	var p := modal("BUILD RECENT FORM", 780, 360)
	label_at(p, "Run 160 quick races for roughly 80% of the stable.\nMany horses gain several recent finishes; some stay unraced.\nExisting results are kept. No bets, bankroll changes or high scores.\nThis is available once and carries into new visits and Continue.", Vector2(28, 95), 17)
	button_at(p, "SIMULATE RACES", Rect2(28, 273, 340, 48), run_history_simulation)

func run_history_simulation() -> void:
	if in_game or model.history_seeded:
		return
	var previous := model.persistent_data()
	var simulation = HistorySimulation.new(previous)
	var p := modal("SIMULATING RECENT FORM", 780, 300)
	var progress := label_at(p, "Preparing background meetings…", Vector2(28, 105), 20)
	label_at(p, "Close to cancel. Results are saved only when all races finish.", Vector2(28, 175), 16, MUTED)
	var active_dialog := dialog_layer
	for i in range(HistorySimulation.RACE_COUNT):
		await get_tree().process_frame
		if not is_instance_valid(active_dialog) or dialog_layer != active_dialog:
			return
		simulation.run_next()
		progress.text = "%d / %d races complete" % [simulation.completed, HistorySimulation.RACE_COUNT]
	model.load_persistent(simulation.persistent_data())
	var saved := save_history()
	if not saved:
		model.load_persistent(previous)
	update_history_button()
	p = modal("RECENT FORM READY" if saved else "COULD NOT SAVE RECENT FORM", 780, 320)
	if saved:
		label_at(p, "%d races recorded. %d of %d horses now have recent form.\nSome horses remain newcomers. Player bankrolls are unchanged.\nHead to the track or Continue to use the results." % [simulation.valid_races, model.recent_results.size(), model.stable.size()], Vector2(28, 105), 18)
	else:
		label_at(p, "Records could not be written to disk. Existing history is unchanged.\nCheck that the save folder is writable, then try again.", Vector2(28, 105), 18)

func add_graphics_choice(pos: Vector2, dimensions: Vector2) -> void:
	graphics_choice = OptionButton.new()
	graphics_choice.position = pos
	graphics_choice.size = dimensions
	graphics_choice.add_item("Classic — 1992 graphics")
	graphics_choice.add_item("Enhanced graphics")
	graphics_choice.add_item("Animated horses")
	graphics_choice.select(graphics_mode)
	graphics_choice.item_selected.connect(set_graphics_mode)
	body.add_child(graphics_choice)

func set_graphics_mode(index: int) -> void:
	graphics_mode = clampi(index, Artwork.CLASSIC, Artwork.ANIMATED)
	graphics_choice.select(graphics_mode)
	var settings := ConfigFile.new()
	settings.load(settings_path)
	settings.set_value("graphics", "mode", Artwork.MODE_KEYS[graphics_mode])
	settings.save(settings_path)
	update_portrait()
	if track:
		update_track_artwork()

func update_portrait() -> void:
	if title_portrait:
		title_portrait.texture = Artwork.portrait(graphics_mode)
		title_portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST if graphics_mode == Artwork.CLASSIC else CanvasItem.TEXTURE_FILTER_LINEAR

func update_track_artwork() -> void:
	track.frames = Artwork.race_frames(graphics_mode)
	track.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR if graphics_mode == Artwork.REMASTERED else CanvasItem.TEXTURE_FILTER_NEAREST
	track.queue_redraw()

func start_new() -> void:
	var chosen: Array = []
	for edit in names:
		chosen.append(edit.text)
	var selected_mode: String = Model.FORM if mode_choice.selected == 1 else Model.ORIGINAL
	set_game_mode(mode_choice.selected)
	model.new_game(chosen, -1, selected_mode)
	load_auto_preferences()
	remember_player_names(model.players.map(func(player): return player.name))
	build_game()
	save_game(false)

func build_game() -> void:
	in_game = true
	reset_body()
	label_at(body, "RACE THE NAGS", Vector2(28, 18), 32)
	label_at(body, "%s MODE  /  THE PADDOCK" % model.mode_name().to_upper(), Vector2(29, 61), 12, GOLD)
	add_graphics_choice(Vector2(360, 48), Vector2(254, 36))
	button_at(body, "?  Help", Rect2(662, 26, 88, 36), show_help)
	button_at(body, "Save", Rect2(760, 26, 82, 36), save_game)
	button_at(body, "Records", Rect2(852, 26, 110, 36), show_fame)
	button_at(body, "Sound", Rect2(972, 26, 100, 36), toggle_sound)
	button_at(body, "Go home", Rect2(1082, 26, 170, 36), go_home)
	phase_label = label_at(body, "", Vector2(28, 106), 18, GOLD)
	status_label = label_at(body, "", Vector2(380, 108), 14, MUTED)
	track = Track.new()
	track.model = model
	track.bazooka_requested.connect(fire_bazooka)
	track.position = Vector2(28, 145)
	track.size = Vector2(834, 342)
	update_track_artwork()
	body.add_child(track)
	var card := panel(body, Rect2(888, 100, 364, 470))
	label_at(card, "TODAY’S RUNNERS", Vector2(20, 17), 19, GOLD)
	label_at(card, "SILKS / HORSE", Vector2(20, 53), 11, MUTED)
	label_at(card, "ODDS", Vector2(290, 53), 11, MUTED)
	for i in range(6):
		var y := 84 + i * 54
		var badge := label_at(card, str(i + 1), Vector2(20, y), 23, Track.SILKS[i])
		badge.tooltip_text = "Horse %d" % (i + 1)
		var l := label_at(card, "", Vector2(53, y + 2), 14)
		l.size.x = 233
		l.clip_text = true
		card_labels.append(l)
		card_labels.append(label_at(card, "", Vector2(292, y + 2), 17, GOLD))
		var recent := label_at(card, "", Vector2(53, y + 25), 11, MUTED)
		recent.size.x = 284
		recent.clip_text = true
		recent_labels.append(recent)
	if model.mode == Model.FORM:
		button_at(card, "RACING FORM", Rect2(20, 414, 324, 40), show_racing_form, ARROW_UP_RIGHT)
	else:
		button_at(card, "HORSE STATISTICS", Rect2(20, 414, 324, 40), show_stats, ARROW_UP_RIGHT)
	var bets := panel(body, Rect2(28, 508, 834, 213))
	label_at(bets, "THE BETTING SLIP", Vector2(18, 12), 16, GOLD)
	label_at(bets, "PLAYER / BANKROLL", Vector2(18, 43), 11, MUTED)
	label_at(bets, "STAKE $", Vector2(274, 43), 11, MUTED)
	label_at(bets, "HORSE", Vector2(401, 43), 11, MUTED)
	label_at(bets, "BET TYPE" if model.mode == Model.FORM else "FINISH", Vector2(637, 43), 11, MUTED)
	var scroll := ScrollContainer.new()
	scroll.position = Vector2(12, 63)
	scroll.size = Vector2(810, 142)
	bets.add_child(scroll)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list)
	for i in range(model.players.size()):
		var row := Control.new()
		row.custom_minimum_size = Vector2(790, 64)
		list.add_child(row)
		var l := label_at(row, "", Vector2(6, 7), 15)
		l.size.x = 244
		l.clip_text = true
		balance_labels.append(l)
		var amount := SpinBox.new()
		amount.position = Vector2(262, 1)
		amount.size = Vector2(112, 38)
		amount.min_value = 2
		amount.max_value = 1000
		amount.step = 1
		row.add_child(amount)
		var horse := OptionButton.new()
		horse.position = Vector2(389, 1)
		horse.size = Vector2(220, 38)
		for j in range(6):
			horse.add_item(str(j + 1))
		row.add_child(horse)
		var kind := OptionButton.new()
		kind.position = Vector2(625, 1)
		kind.size = Vector2(151, 38)
		for k in range(Model.BET_LABELS.size() if model.mode == Model.FORM else 3):
			kind.add_item(["WIN • 1st", "PLACE • Top 2", "SHOW • Top 3"][k] if k < 3 else Model.BET_LABELS[k])
			kind.set_item_tooltip(k, Model.BET_HELP[k])
		row.add_child(kind)
		var summary := label_at(row, "", Vector2(6, 41), 13, GOLD)
		summary.size.x = 770
		summary.clip_text = true
		var selection := button_at(row, "", Rect2(389, 1, 220, 38), func(): show_ticket_picker(i))
		selection.visible = false
		bet_rows.append({"amount": amount, "horse": horse, "kind": kind, "summary": summary, "selection": selection})
		amount.value_changed.connect(func(_v): sync_bets())
		horse.item_selected.connect(func(_v): sync_bets())
		kind.item_selected.connect(func(index): change_ticket_kind(i, index))
	var auto_panel := panel(body, Rect2(888, 585, 364, 136))
	label_at(auto_panel, "AUTO STRATEGY", Vector2(14, 8), 12, GOLD)
	auto_strategy_choice = OptionButton.new()
	auto_strategy_choice.position = Vector2(14, 30)
	auto_strategy_choice.size = Vector2(190, 36)
	auto_strategy_choice.add_theme_font_size_override("font_size", 14)
	for i in range(Model.AUTO_STRATEGIES.size()):
		var strategy: String = Model.AUTO_STRATEGIES[i]
		auto_strategy_choice.add_item(Model.AUTO_LABELS[i])
		auto_strategy_choice.set_item_tooltip(i, Model.AUTO_TOOLTIPS[i] + " Ties use the lowest runner number.")
		auto_strategy_choice.set_item_disabled(i, strategy in Model.AUTO_REMASTERED_ONLY and model.mode != Model.FORM)
	auto_strategy_choice.select(Model.AUTO_STRATEGIES.find(model.auto_strategy))
	auto_strategy_choice.item_selected.connect(func(index):
		model.auto_strategy = Model.AUTO_STRATEGIES[index]
		save_preference("auto_" + model.mode, "strategy", model.auto_strategy)
		save_game(false))
	auto_panel.add_child(auto_strategy_choice)
	label_at(auto_panel, "BET TYPE" if model.mode == Model.FORM else "FINISH", Vector2(216, 8), 12, GOLD)
	auto_kind_choice = OptionButton.new()
	auto_kind_choice.position = Vector2(216, 30)
	auto_kind_choice.size = Vector2(133, 36)
	for kind_label in Model.BET_LABELS.slice(0, Model.BET_LABELS.size() if model.mode == Model.FORM else 3) + ["Random"]:
		auto_kind_choice.add_item(kind_label)
	auto_kind_choice.add_theme_font_size_override("font_size", 14)
	for k in range(auto_kind_choice.item_count - 1):
		auto_kind_choice.set_item_tooltip(k, Model.BET_HELP[k])
	auto_kind_choice.tooltip_text = "Choose a bet type. Auto picks distinct runners using the selected strategy. Random varies Win/Place/Show."
	auto_kind_choice.select(auto_kind_choice.item_count - 1 if model.auto_kind == -1 else model.auto_kind)
	auto_kind_choice.item_selected.connect(func(index):
		model.auto_kind = -1 if index == auto_kind_choice.item_count - 1 else index
		save_preference("auto_" + model.mode, "kind", model.auto_kind)
		save_game(false))
	auto_panel.add_child(auto_kind_choice)
	label_at(auto_panel, "RACES", Vector2(14, 70), 10, MUTED)
	label_at(auto_panel, "STAKE / PLAYER", Vector2(120, 70), 10, MUTED)
	auto_count = SpinBox.new()
	auto_count.position = Vector2(14, 86)
	auto_count.size = Vector2(94, 36)
	auto_count.min_value = 1
	auto_count.max_value = 1000
	auto_count.value = model.auto_remaining if model.auto_remaining > 0 else auto_integer_preference("count", 10, 1, 1000)
	auto_count.value_changed.connect(func(value): save_preference("auto_" + model.mode, "count", int(value)))
	auto_count.tooltip_text = "Number of automatic races"
	auto_panel.add_child(auto_count)
	auto_amount = SpinBox.new()
	auto_amount.position = Vector2(120, 86)
	auto_amount.size = Vector2(97, 36)
	auto_amount.min_value = 0
	auto_amount.max_value = 1000
	auto_amount.value = model.auto_stake / 100.0
	auto_amount.value_changed.connect(func(value):
		model.auto_stake = int(value) * 100
		save_preference("auto_" + model.mode, "stake", model.auto_stake)
		save_game(false))
	auto_amount.prefix = "$"
	auto_amount.tooltip_text = "Fixed stake per player per race; $0 uses 10% of bankroll"
	auto_panel.add_child(auto_amount)
	auto_button = button_at(auto_panel, "Run auto", Rect2(229, 86, 120, 36), toggle_auto)
	primary_button = button_at(body, "", Rect2(582, 739, 280, 44), primary_action, ARROW_RIGHT)
	notice = label_at(body, "F1 Help   F8 Save   F10 Sound   Alt+S Stats", Vector2(28, 752), 13, MUTED)
	notice.size.x = 540
	notice.clip_text = true
	button_at(body, "Pause / Resume", Rect2(888, 739, 170, 44), toggle_pause)
	button_at(body, "Millionaires", Rect2(1070, 739, 182, 44), show_million)
	update_game()
	if not model.can_play() and model.phase != "RACING":
		show_game_over()

func sync_bets() -> void:
	if model.phase != "BETTING":
		return
	for i in range(bet_rows.size()):
		var row: Dictionary = bet_rows[i]
		if int(model.players[i].cash) >= Model.MIN_BET:
			model.set_bet(i, row.horse.selected, row.kind.selected, int(row.amount.value) * 100, model.ticket_runners(model.players[i]) if row.kind.selected > 2 else [])
	update_bet_markers()

func change_ticket_kind(player_id: int, kind: int) -> void:
	if model.phase != "BETTING":
		return
	var row: Dictionary = bet_rows[player_id]
	var runners := [row.horse.selected]
	for runner in range(6):
		if runners.size() >= Model.runner_count(kind):
			break
		if not runner in runners:
			runners.append(runner)
	model.set_bet(player_id, runners[0], kind, int(row.amount.value) * 100, runners)
	update_game()
	if kind > 2:
		show_ticket_picker(player_id)

func show_ticket_picker(player_id: int) -> void:
	if model.phase != "BETTING" or model.auto_remaining > 0:
		return
	var player: Dictionary = model.players[player_id]
	var kind := int(player.kind)
	if kind <= 2 or model.mode != Model.FORM:
		return
	var p := modal("BUILD YOUR %s" % Model.BET_LABELS[kind].to_upper(), 820, 560)
	label_at(p, Model.BET_HELP[kind] + ".", Vector2(28, 82), 18)
	label_at(p, "Total ticket cost: %s (includes all covered orders)" % money(int(player.stake)), Vector2(28, 119), 16, GOLD)
	ticket_choices.clear()
	var runners: Array = model.ticket_runners(player)
	for slot in range(Model.runner_count(kind)):
		var y := 168 + slot * 58
		label_at(p, "Horse %d" % (slot + 1) if kind in [Model.QUINELLA, Model.BOX_TRIFECTA] else ["1st", "2nd", "3rd"][slot], Vector2(28, y + 8), 16, MUTED)
		var choice := OptionButton.new()
		choice.position = Vector2(140, y)
		choice.size = Vector2(645, 40)
		for runner in range(6):
			choice.add_item("#%d  %s   (%d:1)" % [runner + 1, model.field[runner].name, model.field[runner].odds])
		choice.select(int(runners[slot]))
		p.add_child(choice)
		ticket_choices.append(choice)
		choice.item_selected.connect(func(_index): update_ticket_preview(player_id))
	ticket_preview = label_at(p, "", Vector2(28, 355), 18, GOLD)
	label_at(p, "Game quote: multiply selected odds; divide by 2 for Quinella or 6 for Box trifecta.\nReturn includes your stake. These are arcade payouts, not real racing dividends.", Vector2(28, 401), 14, MUTED)
	ticket_apply = button_at(p, "CONFIRM TICKET", Rect2(28, 480, 757, 45), func():
		var chosen := []
		for choice in ticket_choices:
			chosen.append(choice.selected)
		if model.set_bet(player_id, chosen[0], kind, int(player.stake), chosen):
			close_modal()
			update_game()
			save_game(false))
	update_ticket_preview(player_id)

func update_ticket_preview(player_id: int) -> void:
	var chosen := []
	for choice in ticket_choices:
		chosen.append(choice.selected)
	var player: Dictionary = model.players[player_id]
	var valid := Model.valid_runners(int(player.kind), chosen)
	ticket_apply.disabled = not valid
	ticket_preview.text = "Return if won: %s" % money(model.exotic_quote(int(player.stake), int(player.kind), chosen)) if valid else "Pick a different horse for every slot."

func bet_description(player: Dictionary) -> String:
	var active: bool = int(player.cash) >= Model.MIN_BET if model.phase == "BETTING" else bool(player.get("racing", false))
	if not active:
		return "Sitting out this race"
	if int(player.kind) > 2:
		var numbers := PackedStringArray()
		for runner in model.ticket_runners(player):
			numbers.append("#%d" % (int(runner) + 1))
		var order_text := "any order" if int(player.kind) in [Model.QUINELLA, Model.BOX_TRIFECTA] else "in order"
		return "%s total · %s %s (%s) · Return if won: %s" % [money(int(player.stake)), Model.BET_LABELS[int(player.kind)], " / ".join(numbers), order_text, money(model.exotic_quote(int(player.stake), int(player.kind), model.ticket_runners(player)))]
	return "%s on #%d %s · %s" % [money(int(player.stake)), int(player.horse) + 1, model.field[int(player.horse)].name, ["WIN · needs 1st", "PLACE · needs top 2", "SHOW · needs top 3"][int(player.kind)]]

func update_bet_markers() -> void:
	for i in range(bet_rows.size()):
		var description := bet_description(model.players[i])
		bet_rows[i].summary.text = description
		bet_rows[i].summary.tooltip_text = description
	if track:
		track.queue_redraw()

func update_game() -> void:
	phase_label.text = "RACE %02d  /  %s" % [model.race_number, {"BETTING": "PLACE YOUR BETS", "RACING": "AND THEY’RE OFF!", "RESULTS": "OFFICIAL RESULTS"}[model.phase]]
	auto_strategy_choice.disabled = model.auto_remaining > 0 or model.phase == "RACING"
	auto_kind_choice.disabled = auto_strategy_choice.disabled
	auto_button.text = "Cancel auto" if model.auto_remaining > 0 else "Run auto"
	auto_button.disabled = model.auto_remaining == 0 and model.phase == "RACING"
	auto_button.tooltip_text = "Stop future bets. The current race will finish and settle." if model.auto_remaining > 0 else "Start automatic betting"
	auto_count.editable = not auto_strategy_choice.disabled
	auto_amount.editable = not auto_strategy_choice.disabled
	status_label.text = "Auto: %s / %s • %d left" % [Model.AUTO_LABELS[Model.AUTO_STRATEGIES.find(model.auto_strategy)], (Model.BET_LABELS[model.auto_kind] if model.auto_kind >= 0 else "Random"), model.auto_remaining] if model.auto_remaining > 0 else ("Watch for a change of lead…" if model.phase == "RACING" else "$2 minimum · $1,000 maximum")
	for i in range(6):
		card_labels[i * 2].text = model.field[i].name
		card_labels[i * 2 + 1].text = "%d:1" % model.field[i].odds
		if model.mode == Model.FORM:
			var racing: Dictionary = model.racing_card(i)
			recent_labels[i].text = "%s  /  %s" % [racing.recent, racing.style]
			recent_labels[i].tooltip_text = "Recent finishes, newest first. DNF = did not finish.
Speed %d/5 · Stamina %d/5 · Consistency %d/5" % [racing.speed, racing.stamina, racing.consistency]
		else:
			recent_labels[i].text = ""
	for i in range(bet_rows.size()):
		var p: Dictionary = model.players[i]
		balance_labels[i].text = "%s   %s" % [p.name, money(int(p.cash))]
		var row: Dictionary = bet_rows[i]
		var editable: bool = model.phase == "BETTING" and int(p.cash) >= 200
		row.amount.editable = editable
		row.horse.visible = int(p.kind) <= 2
		row.selection.visible = int(p.kind) > 2
		row.selection.disabled = not editable
		var selected_numbers := PackedStringArray()
		for runner in model.ticket_runners(p):
			selected_numbers.append("#%d" % (int(runner) + 1))
		row.selection.text = " / ".join(selected_numbers) + "  · Edit"
		row.horse.disabled = not editable
		row.kind.disabled = not editable
		row.amount.set_block_signals(true)
		row.amount.max_value = maxf(2, minf(1000, floor(float(p.cash) / 100.0)))
		row.amount.value = maxf(2, float(p.stake) / 100.0)
		row.amount.set_block_signals(false)
		for j in range(6):
			row.horse.set_item_text(j, "%d  %s" % [j + 1, str(model.field[j].name).left(18)])
		row.horse.select(int(p.horse))
		row.kind.select(int(p.kind))
	update_bet_markers()
	primary_button.text = "START THE RACE" if model.phase == "BETTING" else ("NEXT RACE" if model.phase == "RESULTS" else "RACE IN PROGRESS…")
	primary_button.icon = ARROW_RIGHT if model.phase in ["BETTING", "RESULTS"] else null
	primary_button.disabled = model.phase == "RACING" or not model.can_play()
	if not model.can_play() and model.phase != "RACING":
		primary_button.text = "BANKROLLS EMPTY"
		primary_button.icon = null

func primary_action() -> void:
	if not in_game or dialog_layer:
		return
	if model.phase == "BETTING":
		sync_bets()
		if model.start_race():
			play_tone(850, 0.13)
			update_game()
			save_game(false)
	elif model.phase == "RESULTS":
		model.next_race()
		update_game()
		save_game(false)

func _process(delta: float) -> void:
	if game_over_active:
		game_over_remaining -= delta
		game_over_countdown.text = "Returning home in %d…" % maxi(0, int(ceil(game_over_remaining)))
		if game_over_remaining <= 0:
			show_title()
		return
	if not in_game or dialog_layer:
		return
	if model.phase == "RACING":
		audio_timer += delta
		if audio_timer > 0.22:
			audio_timer = 0
			play_tone(110 + int(model.elapsed * 10) % 3 * 30, 0.025, 0.07)
		if model.advance(delta):
			race_finished()

func race_finished() -> void:
	if model.auto_remaining > 0:
		model.auto_remaining -= 1
	update_game()
	save_game(false)
	show_results()

func fire_bazooka() -> void:
	if not in_game or dialog_layer:
		return
	var target: int = model.fire_bazooka()
	if target < 0:
		return
	track.show_blast(target)
	notice.text = "Stray rocket! #%d %s is out. That crate is empty." % [target + 1, model.field[target].name]
	play_tone(48, 0.5, 0.9)
	if model.phase == "RESULTS":
		race_finished()
	else:
		save_game(false)

func toggle_auto() -> void:
	if not in_game:
		return
	if model.phase != "RACING" and not model.can_play():
		show_game_over()
		return
	if model.auto_remaining > 0:
		cancel_auto()
		return
	if model.phase == "RACING":
		return
	auto_run_serial += 1
	model.auto_remaining = int(auto_count.value)
	model.auto_stake = int(auto_amount.value) * 100
	if model.phase == "RESULTS":
		model.next_race()
	model.automatic_bets()
	model.start_race()
	update_game()
	save_game(false)

func cancel_auto() -> void:
	if not in_game or model.auto_remaining <= 0:
		return
	model.auto_remaining = 0
	auto_run_serial += 1
	notice.text = "Auto cancelled. Current race will finish; no further bets." if model.phase == "RACING" else "Auto cancelled. No further bets will be placed."
	if is_instance_valid(results_auto_button):
		results_auto_button.text = "AUTO CANCELLED"
		results_auto_button.disabled = true
	update_game()
	save_game(false)

func modal(title_value: String, width: float = 810, height: float = 610) -> Panel:
	close_modal()
	dialog_layer = Control.new()
	dialog_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	body.add_child(dialog_layer)
	var shade := ColorRect.new()
	shade.color = Color(0.015, 0.04, 0.03, 0.88)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dialog_layer.add_child(shade)
	var p := panel(dialog_layer, Rect2((1280 - width) / 2, (800 - height) / 2, width, height), Color("183b2e"))
	label_at(p, title_value, Vector2(28, 22), 26, GOLD)
	button_at(p, "CLOSE  ×", Rect2(width - 143, 23, 115, 36), close_modal)
	return p

func close_modal() -> void:
	if dialog_layer:
		dialog_layer.get_parent().remove_child(dialog_layer)
		dialog_layer.queue_free()
		dialog_layer = null

func show_results() -> void:
	if not model.can_play():
		show_game_over()
		return
	var p := modal("RACE %02d  /  THE RESULTS" % model.race_number, 850, 630)
	for i in range(model.finish_order.size()):
		var horse_id := int(model.finish_order[i])
		var order_label := label_at(p, "%d.  %s" % [i + 1, model.field[horse_id].name], Vector2(28 + (i % 2) * 400, 85 + (i / 2) * 30), 16)
		order_label.size.x = 380
		order_label.clip_text = true
	label_at(p, "PLAYER", Vector2(28, 205), 14, MUTED)
	label_at(p, "RETURN", Vector2(310, 205), 14, MUTED)
	label_at(p, "NET", Vector2(475, 205), 14, MUTED)
	label_at(p, "BANKROLL", Vector2(650, 205), 14, MUTED)
	for i in range(model.results.size()):
		var r: Dictionary = model.results[i]
		var y := 241 + i * 43
		var player_label := label_at(p, r.name, Vector2(28, y - 4), 16)
		player_label.size.x = 265
		player_label.clip_text = true
		var selection := label_at(p, bet_description(model.players[i]), Vector2(28, y + 17), 11, GOLD)
		selection.size.x = 265
		selection.clip_text = true
		selection.tooltip_text = bet_description(model.players[i])
		label_at(p, money(int(r["return"])), Vector2(310, y), 16)
		label_at(p, money(int(r.net)), Vector2(475, y), 16, GOLD if int(r.net) > 0 else MUTED)
		label_at(p, money(int(model.players[i].cash)), Vector2(650, y), 16)
	label_at(p, "Race void: four runners are out. All stakes refunded." if model.void_race else ("All finishers are official. Return includes your original stake." if model.mode == Model.FORM else "Top three are official. Return includes your original stake."), Vector2(28, 520), 14, MUTED)
	button_at(p, "BACK TO THE TRACK", Rect2(28, 564, 530 if model.auto_remaining > 0 else 790, 42), finish_results, ARROW_RIGHT)
	if model.auto_remaining > 0 and model.can_play():
		results_auto_button = button_at(p, "CANCEL AUTO", Rect2(578, 564, 240, 42), cancel_auto)
		results_auto_button.tooltip_text = "Stop here without placing another bet."
		var scheduled_run := auto_run_serial
		var scheduled_race: int = model.race_number
		var timer := get_tree().create_timer(3.0)
		timer.timeout.connect(func():
			if in_game and model.phase == "RESULTS" and model.auto_remaining > 0 and auto_run_serial == scheduled_run and model.race_number == scheduled_race:
				finish_results())

func finish_results() -> void:
	if not in_game:
		return
	if not model.can_play():
		show_game_over()
		return
	close_modal()
	if model.auto_remaining > 0 and model.can_play():
		model.next_race()
		model.automatic_bets()
		model.start_race()
	update_game()
	save_game(false)

func show_game_over() -> void:
	# Stakes are deducted during racing; only settled bankrolls end a visit.
	if game_over_active or not in_game or model.phase == "RACING" or model.can_play():
		return
	model.auto_remaining = 0
	record_visit()
	# A finished visit must not be offered by Continue Saved Game.
	DirAccess.remove_absolute(save_path)
	in_game = false
	game_over_active = true
	game_over_remaining = GAME_OVER_SECONDS
	reset_body()
	var p := panel(body, Rect2(190, 70, 900, 660))
	label_at(p, "GAME OVER  /  FINAL SCOREBOARD", Vector2(32, 30), 30, GOLD)
	label_at(p, "No player has enough left for the $2 minimum bet.", Vector2(32, 85), 19)
	label_at(p, "%s mode · Race %02d · Scores recorded" % [model.mode_name(), model.race_number], Vector2(32, 120), 16, MUTED)
	label_at(p, "PLAYER", Vector2(32, 180), 14, MUTED)
	label_at(p, "FINAL BANKROLL", Vector2(450, 180), 14, MUTED)
	label_at(p, "VISIT NET", Vector2(680, 180), 14, MUTED)
	var standings: Array = model.players.duplicate(true)
	standings.sort_custom(func(a, b): return int(a.cash) > int(b.cash))
	for i in range(standings.size()):
		var player: Dictionary = standings[i]
		var y := 222 + i * 47
		label_at(p, "%02d   %s" % [i + 1, player.name], Vector2(32, y), 20)
		label_at(p, money(int(player.cash)), Vector2(450, y), 20, GOLD)
		label_at(p, money(int(player.cash) - 5000), Vector2(680, y), 20, MUTED)
	game_over_countdown = label_at(p, "Returning home in %d…" % int(GAME_OVER_SECONDS), Vector2(32, 537), 18, MUTED)
	button_at(p, "HOME  /  START AGAIN", Rect2(32, 585, 836, 44), show_title, ARROW_RIGHT).grab_focus()
	play_death_music()

func show_help() -> void:
	var p := modal("A DAY AT THE RACES", 850, 750)
	var copy := "\n".join([
		"Pick a horse, set a stake, then choose Win, Place or Show.",
		"Each player starts with $50. Stakes run from $2 to $1,000.",
		"",
		"WIN: first.  PLACE: top two.  SHOW: top three.",
		"Win returns stake × odds. Place/Show return stake plus reduced profit.",
		"Fallen jockeys are out. Four falls void the race and refund all stakes.",
		"",
		"ORIGINAL: recovered random turns and penalties above 10:1 and 15:1.",
		"REMASTERED: horse traits, recent form and multi-horse bets.",
		"Weighted ballots choose who advances. The odds are a public estimate.",
		"Open Racing Form for traits and the last five finishes, newest first.",
		"",
		"F1 Help    F8 Save    F10 Sound    Escape Pause / Close",
		"Alt+S Stats    Alt+V Hall of Fame    Alt+M Millionaires    Alt+Z Boss",
		"Space starts / advances a race when a form control has no focus.",
		"",
		"REMASTERED BETS: Quinella (top 2, any order), Exacta (top 2, ordered).",
		"Trifecta: top 3 in order. Box trifecta: top 3 in any order. Click Edit to pick.",
		"AUTO: Choose a horse selector and bet type. Random varies Win/Place/Show.",
		"Favourite = lowest odds; Underdog = longest; Outside chance = next longest.",
		"Choose race count and stake. $0 uses 10% of bankroll ($2 minimum).",
		"Cancel auto stops future bets; the current race finishes. You can also press a key.",
		"Names are remembered. Games autosave at race changes and on exit.",
		"F8 saves mid-race. Continue Saved Game restores your whole visit.",
		"Go home records your bankroll. Each mode has its own racing records.",
		"",
		"Original game & Classic art: Dick Olsen / Olsen Outdoors, 1992.",
		"A free preservation tribute, without affiliation or endorsement.",
		"Original graphics are not MIT-licensed. See THIRD_PARTY_NOTICES.md.",
		"Rightsholders/heirs: github.com/rknell/race-the-nags/issues",
		"We will promptly remove affected material on a rightful takedown request."
	])
	var scroll := ScrollContainer.new()
	scroll.name = "HelpScroll"
	scroll.position = Vector2(28, 80)
	scroll.size = Vector2(794, 642)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.focus_mode = Control.FOCUS_ALL
	p.add_child(scroll)
	var content := label_at(scroll, copy, Vector2.ZERO, 15)
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	scroll.grab_focus()

func show_stats() -> void:
	var p := modal("THE STABLE  /  %s RECORDS" % model.mode_name().to_upper(), 880, 630)
	label_at(p, "%d lifetime races  •  Win / Place / Show counts are exact finishing positions" % model.total_races, Vector2(28, 77), 14, MUTED)
	var scroll := ScrollContainer.new()
	scroll.position = Vector2(28, 115)
	scroll.size = Vector2(824, 476)
	p.add_child(scroll)
	var l := Label.new()
	l.add_theme_font_size_override("font_size", 16)
	var lines := "HORSE                                  RUNS       W / P / S       WIN %\n\n"
	for i in range(model.stable.size()):
		var name_value = model.stable[i]
		var n := str(name_value.get("name", "HORSE")) if name_value is Dictionary else str(name_value)
		var s: Dictionary = model.stats.get(str(i), {"runs": 0, "wins": 0, "places": 0, "shows": 0})
		lines += "%s    %d runs    %d / %d / %d    %.1f%%\n" % [n.rpad(28), int(s.runs), int(s.wins), int(s.places), int(s.shows), 100.0 * float(s.wins) / maxf(1, float(s.runs))]
	l.text = lines
	scroll.add_child(l)

func show_fame() -> void:
	var viewing_mode := selected_records_mode()
	var entries: Array = fame.filter(func(r): return r.get("mode", Model.ORIGINAL) == viewing_mode)
	var p := modal("HALL OF FAME  /  %s" % ("REMASTERED" if viewing_mode == Model.FORM else "ORIGINAL"), 800, 620)
	label_at(p, "The ten richest visits to the track. Scores are recorded when you go home.", Vector2(28, 78), 15, MUTED)
	if entries.is_empty():
		label_at(p, "A clean slate. Your name could be the first.", Vector2(28, 140), 20)
	for i in range(mini(10, entries.size())):
		var r: Dictionary = entries[i]
		label_at(p, "%02d   %s" % [i + 1, r.name], Vector2(28, 126 + i * 42), 18)
		label_at(p, money(int(r.cash)), Vector2(420, 126 + i * 42), 18, GOLD)
		label_at(p, r.date, Vector2(615, 130 + i * 42), 13, MUTED)

func show_million() -> void:
	var p := modal("THE MILLIONAIRES CLUB", 800, 600)
	var text_value := "A million-dollar bankroll earns a place here.\n\n"
	var entries: Array = million.filter(func(r): return r.get("mode", Model.ORIGINAL) == selected_records_mode())
	for r in entries:
		text_value += "%s    %s\n" % [r.name, money(int(r.cash))]
	if entries.is_empty():
		text_value += "No members yet. There’s always the next race."
	label_at(p, text_value, Vector2(28, 100), 20)

func toggle_pause() -> void:
	if dialog_layer:
		close_modal()
	else:
		var p := modal("TAKING A BREATHER", 620, 310)
		label_at(p, "The race is paused.\nYour horses will wait for you.", Vector2(28, 104), 23)
		button_at(p, "RESUME", Rect2(28, 229, 560, 44), close_modal)

func boss_mode() -> void:
	var p := modal("C:\\WORK>", 1100, 650)
	label_at(p, "Volume in drive C is WORK\nDirectory of C:\\WORK\n\nREPORT   DOC      23,104   12-31-92\nBUDGET   WK1      14,528   12-31-92\nLETTERS  <DIR>            12-31-92\n\n        3 File(s)      4,194,304 bytes free\n\nC:\\WORK>_\n\nPress Escape to return.", Vector2(28, 95), 22, Color("c3c9bf"))

func save_game(show_feedback: bool = true) -> bool:
	if not in_game:
		return false
	sync_bets()
	# Replace the previous save only after the complete snapshot is on disk.
	var temporary_path := save_path + ".tmp"
	var f := FileAccess.open(temporary_path, FileAccess.WRITE)
	var error := FileAccess.get_open_error()
	if f:
		f.store_string(JSON.stringify(model.snapshot(), "\t", true, true))
		f.flush()
		error = f.get_error()
		f.close()
		if error == OK:
			error = DirAccess.rename_absolute(temporary_path, save_path)
	if error != OK:
		notice.text = "Could not save: %s" % error_string(error)
		return false
	if show_feedback:
		notice.text = "Saved — including the current race."
	save_history()
	return true

func load_game() -> void:
	var f := FileAccess.open(save_path, FileAccess.READ)
	if not f:
		return
	var data = JSON.parse_string(f.get_as_text())
	# A save made before the optional background meetings should inherit them.
	# Its field, prices, bets and RNG remain the saved race's exact snapshot.
	if data is Dictionary and model.history_seeded and data.get("persistent", {}) is Dictionary and not bool(data.get("persistent", {}).get("history_seeded", false)):
		data["persistent"] = model.persistent_data()
		var record: Dictionary = data.persistent.records_by_mode.get(data.get("mode", Model.ORIGINAL), {})
		data["stats"] = record.get("stats", {})
		data["total_races"] = record.get("total_races", 0)
	if data is Dictionary and model.restore(data):
		remember_player_names(model.players.map(func(player): return player.name))
		build_game()
		if in_game and model.phase == "RESULTS":
			show_results()
	else:
		var p := modal("SAVE COULD NOT BE READ", 650, 280)
		label_at(p, "The saved game is incomplete or from another version.\nStart a new visit to the track.", Vector2(28, 105), 17)

func load_history() -> void:
	if not FileAccess.file_exists(history_path):
		return
	var f := FileAccess.open(history_path, FileAccess.READ)
	if not f:
		return
	var data = JSON.parse_string(f.get_as_text())
	if data is Dictionary:
		fame = data.get("fame", [])
		million = data.get("million", [])
		var persistent = data.get("persistent", data)
		if persistent is Dictionary:
			model.load_persistent(persistent)

func save_history() -> bool:
	var temporary_path := history_path + ".tmp"
	var f := FileAccess.open(temporary_path, FileAccess.WRITE)
	if not f:
		return false
	f.store_string(JSON.stringify({"version": 2, "fame": fame, "million": million, "persistent": model.persistent_data()}, "\t", true, true))
	f.flush()
	var error := f.get_error()
	f.close()
	return error == OK and DirAccess.rename_absolute(temporary_path, history_path) == OK

func go_home() -> void:
	if model.phase == "RACING":
		var p := modal("LEAVE THE TRACK?", 650, 320)
		label_at(p, "A race is still running. Save it before you leave?", Vector2(28, 110), 20)
		button_at(p, "SAVE & GO HOME", Rect2(28, 225, 280, 48), func():
			model.auto_remaining = 0
			if save_game():
				record_visit()
				show_title())
		button_at(p, "LEAVE WITHOUT SAVING", Rect2(330, 225, 290, 48), func(): record_visit(); show_title())
	else:
		model.auto_remaining = 0
		if save_game():
			record_visit()
			show_title()

func record_visit() -> void:
	model.auto_remaining = 0
	for p in model.players:
		var r := {"name": p.name, "cash": int(p.cash), "date": Time.get_date_string_from_system(), "mode": model.mode}
		fame.append(r)
		if int(p.cash) >= 100000000:
			million.append(r)
	fame.sort_custom(func(a, b): return int(a.cash) > int(b.cash))
	var trimmed: Array = []
	for game_mode in [Model.ORIGINAL, Model.FORM]:
		var count := 0
		for entry in fame:
			if entry.get("mode", Model.ORIGINAL) == game_mode and count < 10:
				trimmed.append(entry)
				count += 1
	fame = trimmed
	save_history()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		if in_game:
			save_game()
			record_visit()
		get_tree().quit()

func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	# Switching windows/tabs must not count as a request to cancel auto.
	# The modifier arrives before the OS/browser consumes the shortcut.
	if event.keycode in [KEY_SHIFT, KEY_CTRL, KEY_ALT, KEY_META] or event.keycode == KEY_TAB and (event.alt_pressed or event.ctrl_pressed or event.meta_pressed):
		return
	if game_over_active:
		if event.keycode == KEY_ESCAPE:
			show_title()
		elif event.keycode == KEY_F10:
			toggle_sound()
		return
	if in_game and model.auto_remaining > 0:
		cancel_auto()
	if event.keycode == KEY_F10:
		toggle_sound()
	elif event.keycode == KEY_F8:
		save_game()
	elif event.keycode == KEY_F1:
		show_help()
	elif event.keycode == KEY_ESCAPE:
		if dialog_layer:
			close_modal()
		elif in_game:
			toggle_pause()
	elif event.alt_pressed and event.keycode == KEY_S and in_game:
		show_stats()
	elif event.alt_pressed and event.keycode == KEY_V:
		show_fame()
	elif event.alt_pressed and event.keycode == KEY_M:
		show_million()
	elif event.alt_pressed and event.keycode == KEY_Z and in_game:
		boss_mode()
	elif event.keycode == KEY_SPACE and in_game:
		primary_action()

func toggle_sound() -> void:
	sound_on = not sound_on
	save_preference("audio", "enabled", sound_on)
	if not sound_on:
		audio.stop()
	if in_game:
		notice.text = "Sound on" if sound_on else "Sound off"

func setup_audio() -> void:
	audio = AudioStreamPlayer.new()
	audio.volume_db = -16
	add_child(audio)

func play_tone(hz: float, seconds: float, gain: float = 0.2) -> void:
	if not sound_on:
		return
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_8_BITS
	stream.mix_rate = 22050
	var bytes := PackedByteArray()
	bytes.resize(int(seconds * stream.mix_rate))
	for i in range(bytes.size()):
		var envelope := 1.0 - float(i) / bytes.size()
		bytes[i] = int(128 + (1 if sin(TAU * hz * i / stream.mix_rate) > 0 else -1) * 110 * gain * envelope)
	stream.data = bytes
	audio.stream = stream
	audio.play()

func death_music_stream() -> AudioStreamWAV:
	# Chopin's public-domain Funeral March, as a short PC-speaker-style phrase.
	# MIDI pitches: B-flat, D-flat, C, A-flat, F. No sampled recording is used.
	var phrase := [[58, 0.6], [58, 0.2], [58, 0.8], [61, 0.6], [60, 0.2],
		[60, 0.6], [58, 0.2], [58, 0.6], [56, 0.2], [58, 1.4], [0, 0.2],
		[53, 0.6], [53, 0.2], [58, 0.6], [58, 0.2], [58, 1.6]]
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_8_BITS
	stream.mix_rate = 22050
	var bytes := PackedByteArray()
	for note in phrase:
		var count := int(float(note[1]) * stream.mix_rate)
		var offset := bytes.size()
		bytes.resize(offset + count)
		var hz := 440.0 * pow(2.0, (int(note[0]) - 69) / 12.0)
		for i in range(count):
			var envelope := minf(1.0, float(count - i) / 350.0)
			var sounding := int(note[0]) > 0 and i < count * 0.9
			bytes[offset + i] = int(128 + (1 if sin(TAU * hz * i / stream.mix_rate) >= 0 else -1) * 30 * envelope) if sounding else 128
	stream.data = bytes
	return stream

func play_death_music() -> void:
	audio.stop()
	if sound_on:
		audio.stream = death_music_stream()
		audio.play()

static func money(cents: int) -> String:
	return ("-" if cents < 0 else "") + "$%d.%02d" % [absi(cents) / 100, absi(cents) % 100]

func update_mode_description() -> void:
	mode_description.text = "Horse traits, recent form, extra bets and strategy-driven auto play." if mode_choice.selected == 1 else "The original random races, odds and payouts."

func selected_records_mode() -> String:
	if in_game:
		return model.mode
	return Model.FORM if mode_choice.selected == 1 else Model.ORIGINAL

func show_racing_form() -> void:
	if model.mode != Model.FORM:
		show_stats()
		return
	var p := modal("RACING FORM  /  RACE %02d" % model.race_number, 1080, 660)
	label_at(p, "Traits stay with a horse. Daily form stays hidden. Recent finishes read newest first.", Vector2(28, 76), 16, MUTED)
	var headings := [[28, "HORSE"], [290, "LAST FIVE"], [490, "STYLE"], [695, "SPEED"], [800, "STAMINA"], [910, "CONSISTENCY"]]
	for heading in headings:
		label_at(p, heading[1], Vector2(heading[0], 121), 12, GOLD)
	for i in range(6):
		var racing: Dictionary = model.racing_card(i)
		var y := 158 + i * 71
		var name_label := label_at(p, "%d  %s" % [i + 1, racing.name], Vector2(28, y), 16, Track.SILKS[i])
		name_label.size.x = 245
		name_label.clip_text = true
		label_at(p, racing.recent, Vector2(290, y + 1), 15)
		label_at(p, racing.style, Vector2(490, y + 1), 15)
		label_at(p, "%d / 5" % racing.speed, Vector2(695, y + 1), 18)
		label_at(p, "%d / 5" % racing.stamina, Vector2(800, y + 1), 18)
		label_at(p, "%d / 5" % racing.consistency, Vector2(932, y + 1), 18)
		var key := str(int(model.field[i].id))
		var record: Dictionary = model.stats.get(key, {"runs": 0, "wins": 0})
		label_at(p, "%d starts · %d wins" % [int(record.runs), int(record.wins)], Vector2(49, y + 27), 12, MUTED)
	label_at(p, "Speed sets pace. Stamina helps late. Consistency reduces variation. DNF = did not finish.", Vector2(28, 605), 16, MUTED)
