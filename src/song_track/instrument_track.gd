class_name InstrumentTrack
extends Node2D

# The scene that uses this script. Used for the [instantiate] method.
const _scene: PackedScene = preload("res://src/song_track/instrument_track.tscn")

# Create an instance of this scene, with the given parameters.
static func instantiate(song: Song, instrument: Instrument, time_before_start: float) -> InstrumentTrack:
	print("instrument ", instrument , " track created on ", song)
	var track: InstrumentTrack = _scene.instantiate()
	track.song = song
	track.instrument = instrument
	return track


var song: Song
var instrument: Instrument

@export var length: int = 500
@export var beats: int = 4

var beat_length: float:
	get: return float(length) / beats
var beat_duration: float:
	get: return 60.0/song.bpm

var current_beat: int = 0

@onready var path: Path2D = $Path2D

func _ready() -> void:
	var beat_timer = Timer.new()
	beat_timer.wait_time = beat_duration
	beat_timer.one_shot = false
	beat_timer.connect("timeout", new_beat)
	add_child(beat_timer)
	beat_timer.start()


func new_beat() -> void:
	for n in instrument.notes_in_beat(current_beat):
		var note = NoteNode.instantiate(path, beats*beat_duration, n.track, $Visuals.width, current_beat * beat_duration, -beat_duration * n.subbeat)
		$Notes.add_child(note)
	
	current_beat += 1
