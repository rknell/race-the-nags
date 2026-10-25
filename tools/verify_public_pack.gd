extends SceneTree
## Inspect the actual exported pack, not only the source tree.
var failures := 0
var checked := 0

func inspect(path: String) -> void:
	var directory := DirAccess.open(path)
	if directory == null:
		return
	for file in directory.get_files():
		var full := path.path_join(file)
		if path.begins_with("res://assets"):
			checked += 1
			if not full.begins_with("res://assets/public/"):
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
	inspect("res://")
	if checked == 0:
		push_error("Pack has no public artwork")
		failures += 1
	print("Public pack: ", checked, " artwork files checked, ", failures, " failures")
	quit(0 if failures == 0 else 1)
