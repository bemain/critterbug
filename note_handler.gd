extends Node2D

var song: Song
var instrument: Instrument

@export var length: int = 500
@export var beats: int = 4
@export var width: int = 64

var beat_length: float:
	get: return length / beats
var beat_duration: float:
	get: return 60.0/song.bpm

var current_beat: int = 0

var note = load("res://note.tscn")

var path: Path2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	song = SongLoader.load_song("res://songs/jazz_swing.chrp")
	print("Playing: ", song.title)
	instrument = song.instruments[0]
	
	path = $"Path2D"
	
	var beat_timer = Timer.new()
	beat_timer.wait_time = beat_duration
	beat_timer.one_shot = false
	beat_timer.connect("timeout", new_beat)
	add_child(beat_timer)
	beat_timer.start()

func new_beat() -> void:
	for n in instrument.notes_in_beat(current_beat):
		#print("New note on beat ", current_beat, " on track ", n.track, " with offset ", n.subbeat)
		get_child(2).add_child(note.instantiate().init(path, beats*beat_duration, n.track, width, current_beat * beat_duration, -beat_duration * n.subbeat))
	current_beat += 1
