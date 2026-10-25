extends RefCounted
## Public artwork is independently drawn; see tools/generate_artwork.py.
## Graphics selection is independent of racing rules and saved race state.
const CLASSIC := 0
const REMASTERED := 1
const ANIMATED := 2
# Retain stored preference keys for existing players.
const MODE_KEYS := ["classic", "remastered", "animated"]

static func portrait(mode: int) -> Texture2D:
	return load("res://assets/public/portrait-pixel.svg" if mode == CLASSIC else "res://assets/public/portrait.svg")

static func race_frames(mode: int) -> Array[Texture2D]:
	var frames: Array[Texture2D] = []
	if mode == ANIMATED:
		return frames
	if mode == CLASSIC:
		for i in range(30):
			frames.append(load("res://assets/public/pixel/horse_%02d.svg" % i))
		return frames
	var sheet: Texture2D = load("res://assets/public/horse-sheet.svg")
	for i in range(30):
		var frame := AtlasTexture.new()
		frame.atlas = sheet
		frame.region = Rect2((i % 4) * 64, (i / 4) * 64, 64, 64)
		frame.filter_clip = true
		frames.append(frame)
	return frames
