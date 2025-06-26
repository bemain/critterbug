class_name InstrumentTrack
extends Node2D

## Emitted when the user hits a [param note].
signal note_hit(note: Note)


var song: Song
var instrument: Instrument


## The length of the entire track, in pixels.
var length: float = 500:
	get: return path.curve.get_baked_length()

## The length of the part of the track above the hit marker, i.e. the part where notes are "active".
var active_length: float:
	get: return length * hit_marker_position

## The width of the track, in pixels.
##
## Note that this is measured along the track, meaning that the bounding box for the track might be 
## much wider, since the track is not necessarily straight.
var width: float:
	get: return $Visuals.width

## The number of beats shown on the track, above the hit marker.
@export var beats: int = 4
## The number of pixels each note moves per beat.
var beat_length: float:
	get: return active_length / beats
## The duration of each beat, in seconds.
var beat_duration: float:
	get: return 60.0/song.bpm

## The number of seconds this tracks would need to wait between beginning note creation and starting 
## audio playback for the audio and the visuals to be in sync.
var initial_delay: float:
	get: return beats * beat_duration

var current_beat: int = 0

var beat_timer: Timer = Timer.new()

@onready var path: Path2D = $Path2D

## The number of seconds off the user can be for a press to be considered a hit.
@export var hit_window = 0.1

## How much of the track is above the hit marker, as a fraction
var hit_marker_position: float:
	get: return $Visuals.hit_marker_position


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
		var note = NoteNode.instantiate(n, self)
		$Notes.add_child(note)
	
	current_beat += 1


func _input(event):
	for i in range(4):
		if event.is_action_pressed("play_%d" %i):
			_check_note_hit(i)


func _check_note_hit(track: int):
	## Check if a note is currently on the hit marker of the given [track]
	var notes = $Notes.get_children().filter(func(note: NoteNode): return note.note.track == track)
	for note: NoteNode in notes:
		if abs(note.timer - beats * beat_duration) <= hit_window:
			note.queue_free()
			note_hit.emit(note.note)
