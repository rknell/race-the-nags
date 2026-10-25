extends SceneTree
## Inspect the actual exported pack, not only the source tree.
var failures := 0
var checked := 0
var heritage: Dictionary = {}

func inspect(path: String) -> void:
	var directory := DirAccess.open(path)
	if directory == null:
		return
	for file in directory.get_files():
		var full := path.path_join(file)
		if path.begins_with("res://assets"):
			checked += 1
			var source := full.trim_suffix(".remap").trim_suffix(".import")
			if not full.begins_with("res://assets/public/") and source != "res://assets/heritage/provenance.json" and not (source.begins_with("res://assets/heritage/") and heritage.has(source.trim_prefix("res://assets/heritage/"))):
				push_error("Non-public artwork in release pack: " + full)
				failures += 1
		if file.get_extension().to_lower() in ["exe", "pcx", "img", "doc"]:
			push_error("Original distribution file in release pack: " + full)
			failures += 1
	for folder in directory.get_directories():
		if folder in ["application", "evidence"]:
			push_error("Private material in release pack: " + folder)
			failures += 1
		inspect(path.path_join(folder))

func _initialize() -> void:
	var manifest := FileAccess.open("res://assets/heritage/provenance.json", FileAccess.READ)
	if manifest:
		heritage = JSON.parse_string(manifest.get_as_text()).get("files", {})
	if heritage.size() != 34:
		push_error("Missing or incomplete heritage artwork manifest")
		failures += 1
	inspect("res://")
	if checked == 0:
		push_error("Pack has no public artwork")
		failures += 1
	print("Public pack: ", checked, " artwork files checked, ", failures, " failures")
	quit(0 if failures == 0 else 1)
