extends Node
## Singleton responsible for loading songs from disk.
##
## Some [member songs] are loaded automatically at startup from the [member songs_dir] directory,
## and more can be loaded manually with [method load_song].

## Persistent config related to playing songs. TODO: Extend this class to provide centralized defaults.
var config: ConfigFile = ConfigFile.new()
var config_path: String = "user://songs.cfg"

## The audio latency, in milliseconds, set in the settings. The game compensates for it to keep the
## visuals and the judging in sync with what the player hears. It is saved as soon as it changes.
@export var audio_latency_ms: float:
	get: return config.get_value("General", "latency", 0)
	set(value):
		config.set_value("General", "latency", value)
		config.save(config_path)


var songs_dir: String = "res://songs"


## All the songs that have already been loaded.
var songs: Array = []

func _ready() -> void:
	config.load(config_path)
	
	for path in _get_song_paths(songs_dir):
		load_song(path)
	
	if not config.has_section_key("General", "latency"):
		audio_latency_ms = AudioServer.get_output_latency() * 1000

## Get the paths to all .chrp files in the directory at [param path]. 
## Searches recursively.
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


## Load a .chrp file into memory, and add it to the list of [member songs].
func load_song(path: String) -> Song:
	var song := ResourceLoader.load(path) as Song
	if not song in songs:
		songs.append(song)
	return song
