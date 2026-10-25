extends RefCounted
## Classic and owner-supplied Enhanced artwork: see THIRD_PARTY_NOTICES.md.
## Graphics selection is independent of the racing rules and saved race state.
const CLASSIC := 0
const REMASTERED := 1
const ANIMATED := 2
const MODE_KEYS := ["classic", "remastered", "animated"]

static func portrait(mode: int) -> Texture2D:
	var path := "res://assets/heritage/portrait.png"
	if mode != CLASSIC:
		path = "res://assets/heritage/enhanced/nag_transparent_endhanced.png"
	return load(path)

static func race_frames(mode: int) -> Array[Texture2D]:
	var frames: Array[Texture2D] = []
	# Animated uses the track's drawn horses rather than a sprite atlas.
	if mode == ANIMATED:
		return frames
	if mode == CLASSIC:
		for i in range(30):
			frames.append(load("res://assets/heritage/horse_%02d.png" % i))
		return frames
	var horses: Texture2D = load("res://assets/heritage/enhanced/horse_sheet_enhanced.png")
	var pony: Texture2D = load("res://assets/heritage/enhanced/pony_sheet_enhanced.png")
	var cell := horses.get_size() / Vector2(4, 6)
	for i in range(24):
		frames.append(region(horses, Rect2(Vector2(i % 4, i / 4) * cell, cell)))
	# The supplied enhanced PONY image has large top/bottom margins. Its
	# second artwork row contains frames 17–33, at roughly 128px per cell.
	var pony_width := pony.get_width() / 17.0
	for i in range(24, 30):
		# Frames 24–28 have separate arrow graphics immediately below the
		# horse. Exclude those, retaining square logical frames via padding.
		var top := 280.0 if i == 28 else 296.0
		var bottom := 424.0 if i == 29 else 376.0
		var frame := region(pony, Rect2((i % 17) * pony_width, top, pony_width, bottom - top))
		frame.margin = Rect2(0, 0, 0, 128 - frame.region.size.y)
		frames.append(frame)
	return frames

static func region(texture: Texture2D, rect: Rect2) -> AtlasTexture:
	var frame := AtlasTexture.new()
	frame.atlas = texture
	frame.region = rect
	frame.filter_clip = true
	return frame
