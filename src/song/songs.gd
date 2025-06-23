extends Node

var songs_dir: String = "res://songs"

@onready var songs: Array = _get_song_paths(songs_dir).map(load_song)


# Get the paths to all .chrp files in the directory at path. 
# Searches recursively.
func _get_song_paths(path: String) -> Array[String]:
	var file_paths: Array[String] = []
	var dir = DirAccess.open(path)
	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		var file_path = path + "/" + file_name
		if file_name.get_extension() == "chrp":
			file_paths.append(file_path)
		if dir.current_is_dir():
			file_paths += _get_song_paths(file_path)
			
		file_name = dir.get_next()
	return file_paths


# Load a .chrp file into memory.
func load_song(path: String) -> Song:
	return ResourceLoader.load(path) as Song
