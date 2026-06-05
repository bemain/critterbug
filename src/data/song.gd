class_name Song extends Resource

## The title of the song.
@export var title: String
## The artist who wrote the song.
@export var artist: String
## Beats per minute.
@export var bpm: int
## Beats per bar.
@export var bpb: int

## The path to the main audio file for this song. 
## Should generally exclude the sound made by any [member instruments], as they have their own audio 
## files.
@export var audio_path: String

## The instruments the user can select from when playing this song.
@export var instruments: Array[Instrument] = []

func _to_string() -> String:
	return "Song(%s, %s, %d/4 @ %d bpm)" % [title, artist, bpb, bpm] 
