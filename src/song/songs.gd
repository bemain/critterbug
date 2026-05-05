extends Node
## Singleton responsible for loading songs from disk.
##
## Some [member songs] are loaded automatically at startup from the [member songs_dir] directory,
## and more can be loaded manually with [method load_song].

## Persistent config related to playing songs. TODO: Extend this class to provide centralized defaults.
var config: ConfigFile = ConfigFile.new()
var config_path: String = "user://songs.cfg"

## The user-inputted audio latency. We compensate by this to try and sync the visuals with the audio.
@export var audio_latency_ms: float:
	get: return config.get_value("General", "latency", 0)
	set(value): config.set_value("General", "latency", value)


var songs_dir: String = "res://songs"

## All the songs that have already been loaded.
@onready var songs: Array = _get_song_paths(songs_dir).map(load_song)


func _ready() -> void:
	config.load(config_path)
	
	if audio_latency_ms == 0:
		audio_latency_ms = AudioServer.get_output_latency()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		# Game is closing
		config.save(config_path)

## Get the paths to all .chrp files in the directory at path. 
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


## Load a .chrp file into memory, and add it to the loaded [member songs].
func load_song(path: String) -> Song:
	var song := ResourceLoader.load(path) as Song
	if not song in songs:
		songs.append(song)
	return song
