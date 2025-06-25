class_name InstrumentTrack
extends Node2D


var song: Song
var instrument: Instrument

# The number of seconds this tracks would need to wait between beginning note creation and starting 
# audio playback for the audio and the visuals to be in sync.
var initial_delay: float:
	get: return beats * beat_duration
	

# The length of the track, in pixels
@export var length: int = 500
# The number of beats shown on the track
@export var beats: int = 4

var beat_length: float:
	get: return float(length) / beats
var beat_duration: float:
	get: return 60.0/song.bpm

var current_beat: int = 0

var beat_timer: Timer = Timer.new()

@onready var path: Path2D = $Path2D


## Begin creating notes for the given [instrument]. 
##
## Note that the SongManager handles starting audio playback, so that all tracks play simultaneously.
func start() -> void:
	# Reset
	current_beat = 0
	beat_timer.stop()
	
	# Begin creating notes
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
