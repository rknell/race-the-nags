extends SceneTree
const Artwork = preload("res://scripts/artwork.gd")
var failures := 0
var checks := 0

func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(message)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var main = load("res://scenes/main.tscn").instantiate()
	main.settings_path = "user://graphics-test.cfg"
	main.history_path = "user://graphics-test-history.json"
	main.save_path = "user://graphics-test-save.json"
	DirAccess.remove_absolute(main.settings_path)
	root.add_child(main)
	await process_frame
	main.sound_on = false
	check(main.graphics_choice.selected == Artwork.CLASSIC, "Classic is the initial graphics choice")
	check(main.title_portrait.texture.resource_path == "res://assets/heritage/portrait.png", "Classic credits and uses the restored portrait")
	check(main.graphics_choice.item_count == 3, "Classic, Remastered and Animated are offered")
	main.names[0].text = "GRAPHICS TEST"
	main.graphics_choice.item_selected.emit(Artwork.REMASTERED)
	check(main.names[0].text == "GRAPHICS TEST", "Switching title graphics preserves names")
	check(main.title_portrait.texture.resource_path.ends_with("portrait.svg"), "New illustrated portrait displayed")
	main.start_new()
	check(main.track.frames.size() == 30, "Remastered loads 24 gallop frames and six fallen poses")
	check(main.track.frames[0] is AtlasTexture and main.track.frames[0].atlas.resource_path.ends_with("horse-sheet.svg"), "Gallop uses enhanced horse sheet")
	check(main.track.frames[24].atlas.resource_path.ends_with("horse-sheet.svg"), "Falls use enhanced pony sheet")
	for frame in main.track.frames:
		check(Rect2(Vector2.ZERO, frame.atlas.get_size()).encloses(frame.region), "Enhanced frame lies inside source sheet")
	main.primary_action()
	main.model.advance(2)
	var before: String = JSON.stringify(main.model.snapshot(), "", true, true)
	main.graphics_choice.item_selected.emit(Artwork.CLASSIC)
	check(JSON.stringify(main.model.snapshot(), "", true, true) == before, "Live graphics switch preserves race, bets, bankroll and RNG")
	check(main.track.frames[24].resource_path.ends_with("horse_24.png"), "Classic restores the original fallen pose")
	check(main.track.texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST, "Classic uses crisp pixel filtering")
	main.graphics_choice.item_selected.emit(Artwork.REMASTERED)
	check(main.track.texture_filter == CanvasItem.TEXTURE_FILTER_LINEAR, "Remastered uses smooth filtering")
	main.save_game()
	main.show_title()
	main.load_game()
	check(main.graphics_choice.selected == Artwork.REMASTERED, "Continue retains selected graphics")
	main.show_title()
	main.mode_choice.select(1)
	main.start_new()
	check(main.model.mode == "form" and main.track.frames[0] is AtlasTexture, "Remastered also works with Form rules")
	main.graphics_choice.item_selected.emit(Artwork.CLASSIC)
	check(main.model.mode == "form" and not main.track.frames[0] is AtlasTexture, "Classic also works with Form rules")
	main.graphics_choice.item_selected.emit(Artwork.REMASTERED)
	var reopened = load("res://scenes/main.tscn").instantiate()
	reopened.settings_path = main.settings_path
	reopened.history_path = main.history_path
	reopened.save_path = main.save_path
	root.add_child(reopened)
	check(reopened.graphics_choice.selected == Artwork.REMASTERED, "Graphics preference survives app restart")
	reopened.queue_free()
	main.graphics_choice.item_selected.emit(Artwork.ANIMATED)
	check(main.track.frames.is_empty(), "Animated deliberately uses the drawn horses")
	check(main.model.mode == "form", "Animated preserves racing rules")
	main.show_title()
	check(main.title_portrait.texture.resource_path.ends_with("portrait.svg"), "Animated uses the independently drawn portrait")
	var animated_restart = load("res://scenes/main.tscn").instantiate()
	animated_restart.settings_path = main.settings_path
	animated_restart.history_path = main.history_path
	animated_restart.save_path = main.save_path
	root.add_child(animated_restart)
	check(animated_restart.graphics_choice.selected == Artwork.ANIMATED, "Animated preference survives app restart")
	animated_restart.queue_free()
	for path in [main.settings_path, main.history_path, main.save_path]:
		DirAccess.remove_absolute(path)
	main.queue_free()
	await process_frame
	print("Graphics integration: ", checks, " checks, ", failures, " failures")
	quit(0 if failures == 0 else 1)
