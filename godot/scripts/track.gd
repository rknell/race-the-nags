extends Control
signal bazooka_requested
var model: RefCounted
var blast_age := 2.0
var blast_lane := -1
var blast_position := 0.0
var clock := 0.0
var frames: Array[Texture2D] = []
const SILKS := [Color("e9e4d3"), Color("f05649"), Color("62b9eb"), Color("f5ca54"), Color("5cc88a"), Color("c690e8")]
var font := ThemeDB.fallback_font
const BET_GOLD := Color("e6c278")

func backers(horse_id: int) -> Array[String]:
	var names: Array[String] = []
	if model:
		for player in model.players:
			var active: bool = int(player.cash) >= 200 if model.phase == "BETTING" else bool(player.get("racing", false))
			if active and horse_id in model.ticket_runners(player):
				names.append(str(player.name))
	return names

func fit_text(value: String, width: float, font_size: int) -> String:
	if font.get_string_size(value, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x <= width:
		return value
	while not value.is_empty() and font.get_string_size(value + "…", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x > width:
		value = value.left(-1)
	return value + "…"

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS

func _process(delta: float) -> void:
	clock += delta
	blast_age += delta
	tooltip_text = "An unmarked crate. One bazooka round. Any runner could cop it." if model and model.bazooka_available() and crate_rect().has_point(get_local_mouse_position()) else ""
	queue_redraw()

func crate_rect() -> Rect2:
	return Rect2(size.x - 55, size.y - 31, 33, 22)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed and crate_rect().has_point(event.position) and model and model.bazooka_available():
		bazooka_requested.emit()
		accept_event()

func show_blast(lane: int) -> void:
	blast_lane = lane
	blast_position = float(model.field[lane].position)
	blast_age = 0.0

func _draw() -> void:
	draw_style_box(_box(Color("162e27"), 12), Rect2(Vector2.ZERO, size))
	for i in range(6):
		var y := 24.0 + i * 47.0
		draw_rect(Rect2(14, y, size.x - 28, 45), Color("254b36") if i % 2 == 0 else Color("20432f"))
		draw_line(Vector2(14, y + 46), Vector2(size.x - 14, y + 46), Color("56805a"), 1)
		var bettors := backers(i)
		if not bettors.is_empty():
			draw_rect(Rect2(14, y, size.x - 28, 45), Color(0.90, 0.76, 0.47, 0.12))
			draw_rect(Rect2(14, y, 3, 45), BET_GOLD)
		var horse_name := str(i + 1)
		if model and model.field.size() == 6:
			horse_name = "#%d  %s" % [i + 1, model.field[i].name]
		draw_string(font, Vector2(25, y + 18), fit_text(horse_name, 185, 14), HORIZONTAL_ALIGNMENT_LEFT, -1, 14, SILKS[i])
		var bet_label := "BACKED BY " + ", ".join(bettors) if not bettors.is_empty() else ""
		draw_string(font, Vector2(25, y + 35), fit_text(bet_label, 185, 11), HORIZONTAL_ALIGNMENT_LEFT, -1, 11, BET_GOLD)
		for x in range(234, int(size.x - 30), 64):
			draw_line(Vector2(x, y + 43), Vector2(x + 20, y + 43), Color("35583d"), 1)
	var finish := size.x - 52
	for row in range(37):
		for col in range(2):
			draw_rect(Rect2(finish + col * 6, 22 + row * 8, 6, 8), Color("dedfca") if (row + col) % 2 == 0 else Color("1b3029"))
	draw_string(font, Vector2(finish - 20, 16), "FINISH", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("bfc7a6"))
	draw_line(Vector2(225, 22), Vector2(225, 306), Color("8ba879"), 2)
	for i in range(6):
		var y := 24.0 + i * 47.0
		var progress := 0.0
		var fallen := false
		if model and model.field.size() == 6:
			progress = minf(1.0, float(model.field[i].position) / 568.0)
			fallen = model.field[i].fallen
		var x := 225 + progress * (finish - 243)
		if not backers(i).is_empty():
			draw_style_box(_outline(), Rect2(x - 12, y - 1, 52, 46))
		var frame := i * 4 + int(clock * 11 + i) % 4
		if model and model.phase != "RACING":
			frame = i * 4
		if fallen:
			frame = 24 + i
		if frames.size() > frame:
			draw_texture_rect(frames[frame], Rect2(x - 10, y - 3, 48, 48), false)
		else:
			_draw_horse(Vector2(x, y + 22), SILKS[i], fallen)
		if fallen:
			draw_string(font, Vector2(x + 30, y + 24), ("BLASTED" if model and model.field[i].get("blasted", false) else "OUT"), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("f1b29a"))
		elif model and model.finish_order.has(i):
			draw_circle(Vector2(finish + 30, y + 21), 12, Color("d8bc73"))
			draw_string(font, Vector2(finish + 26, y + 26), str(model.finish_order.find(i) + 1), HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("152e26"))
	draw_string(font, Vector2(20, 329), "GOLD OUTLINE = BACKED HORSE  /  BETTOR NAMES BESIDE EACH LANE", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("92aa8c"))
	if model and model.played_races >= 3 and model.phase == "RACING":
		var crate := crate_rect()
		draw_style_box(_box(Color("4b4934") if not model.bazooka_used else Color("303b2d"), 2), crate)
		draw_line(crate.position + Vector2(3, 3), crate.end - Vector2(3, 3), Color("787052"), 2)
		draw_line(crate.position + Vector2(crate.size.x - 3, 3), crate.position + Vector2(3, crate.size.y - 3), Color("787052"), 2)
		draw_string(font, crate.position + Vector2(13, 16), "?" if not model.bazooka_used else "·", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("b0a47b"))
	if blast_lane >= 0 and blast_age < 1.1:
		var impact := Vector2(225 + minf(1.0, blast_position / 568.0) * (finish - 243) + 12, 24 + blast_lane * 47 + 21)
		var launch := crate_rect().get_center()
		if blast_age < 0.25:
			var rocket := launch.lerp(impact, blast_age / 0.25)
			draw_line(launch, rocket, Color("c6c0a0"), 3)
			draw_circle(rocket, 5, Color("ffdc82"))
		else:
			var fade := 1.0 - (blast_age - 0.25) / 0.85
			for ray in range(12):
				var direction := Vector2.from_angle(ray * TAU / 12.0)
				draw_line(impact + direction * 6, impact + direction * (12 + 35 * (1.0 - fade)), Color(1.0, 0.62, 0.19, fade), 4)
			draw_circle(impact, 23 * fade, Color(1.0, 0.85, 0.42, fade))
			draw_string(font, impact + Vector2(-20, -26), "BOOM!", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(1.0, 0.85, 0.42, fade))


func _draw_horse(p: Vector2, silk: Color, fallen: bool) -> void:
	var brown := Color("b77b4a")
	draw_rect(Rect2(p.x, p.y - 6, 25, 13), brown)
	draw_rect(Rect2(p.x + 21, p.y - 15, 8, 14), brown)
	draw_rect(Rect2(p.x + 25, p.y - 16, 12, 6), brown)
	for j in range(4):
		var swing := sin(clock * 15 + j * 2) * 5
		draw_line(p + Vector2(4 + j * 5, 6), p + Vector2(4 + j * 5 + swing, 17), brown, 3)
	if not fallen:
		draw_rect(Rect2(p.x + 8, p.y - 15, 10, 10), silk)
		draw_circle(p + Vector2(15, -19), 4, Color("f3d1a4"))

func _box(color: Color, radius: int) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = color
	box.set_corner_radius_all(radius)
	return box

func _outline() -> StyleBoxFlat:
	var outline := _box(Color(0.90, 0.76, 0.47, 0.08), 6)
	outline.border_color = BET_GOLD
	outline.set_border_width_all(2)
	return outline
