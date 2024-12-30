extends Resource
class_name Song

@export var title: String
@export var artist: String
@export var bpm: int
@export var bpb: int

@export var audio_path: String

@export var instruments: Array[Instrument]

func _to_string() -> String:
	return "Song(%s, %s, %d/4 @ %d bpm)" % [title, artist, bpb, bpm] 
