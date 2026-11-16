extends SceneTree
## Compiles every .gd file under res:// with project settings (autoloads, global classes) active.
## `--check-only` cannot do this: it flags autoload names as unknown identifiers.

func _initialize() -> void:
	var failures := PackedStringArray()
	for path in _find_scripts("res://"):
		var script := load(path) as Script
		if script == null or not script.can_instantiate():
			failures.append(path)
	for path in failures:
		printerr("FAILED: " + path)
	print("check_scripts: %d failed" % failures.size())
	quit(1 if failures.size() > 0 else 0)


func _find_scripts(dir_path: String) -> PackedStringArray:
	var found := PackedStringArray()
	for sub in DirAccess.get_directories_at(dir_path):
		if not sub.begins_with(".") and sub != "addons":
			found.append_array(_find_scripts(dir_path.path_join(sub)))
	for file in DirAccess.get_files_at(dir_path):
		if file.get_extension() == "gd":
			found.append(dir_path.path_join(file))
	return found
