extends RefCounted
## Classic uses credited 1992 artwork; other styles use new artwork.
## Original assets are excluded from MIT; see THIRD_PARTY_NOTICES.md.
## Graphics selection is independent of racing rules and saved race state.
const CLASSIC := 0
const REMASTERED := 1
const ANIMATED := 2
# Retain stored preference keys for existing players.
const MODE_KEYS := ["classic", "remastered", "animated"]

static func portrait(mode: int) -> Texture2D:
	return load("res://assets/heritage/portrait.png" if mode == CLASSIC else "res://assets/public/portrait.svg")

static func race_frames(mode: int) -> Array[Texture2D]:
	var frames: Array[Texture2D] = []
	if mode == ANIMATED:
		return frames
	if mode == CLASSIC:
		for i in range(30):
			frames.append(load("res://assets/heritage/horse_%02d.png" % i))
		return frames
	var sheet: Texture2D = load("res://assets/public/horse-sheet.svg")
	for i in range(30):
		var frame := AtlasTexture.new()
		frame.atlas = sheet
		frame.region = Rect2((i % 4) * 64, (i / 4) * 64, 64, 64)
		frame.filter_clip = true
		frames.append(frame)
	return frames
