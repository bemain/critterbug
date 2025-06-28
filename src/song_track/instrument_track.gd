class_name InstrumentTrack
extends Node2D
## A track that displays the notes played by an [member instrument] and allows the user to hit them 
## using the keyboard.
## 
## If the user presses the right key when a note passes the hit marker, the note is removed and 
## [signal note_hit] is emitted. If a note passes the hit marker without being hit, the 
## [signal note_missed] is emitted instead.


## Emitted when the user hits a [param note].
signal note_hit(note: Note)

## Emitted when the user fails to hit a [param note] in time.
signal note_missed(note: Note)


## The song that is playing on this track.
var song: Song
## The instrument that is playing on this track.
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

## The most recent position in the song reported.
var last_position: float = -INF

@onready var path: Path2D = $Path2D

## The number of seconds off the user can be for a press to be considered a hit.
@export var hit_window = 0.05

## How much of the track is above the hit marker, as a fraction
var hit_marker_position: float:
	get: return $Visuals.hit_marker_position


## Move the notes along the track, and create new ones when needed.
## Should be called every frame with [param song_position] as the current position in the [member song]. 
func update(song_position: float) -> void:
	if song_position <= last_position: return  # Can't go backwards
		
	# Add new notes
	for n in instrument.notes.filter(
		func(note): 
			var note_create_at = (note.beat + note.subbeat - beats) * beat_duration
			return last_position < note_create_at and note_create_at <= song_position
	):
		var note = NoteNode.instantiate(n, self)
		$Notes.add_child(note)
	
	last_position = song_position
	
	# Update notes
	for note: NoteNode in $Notes.get_children():
		note.update(song_position)



func _input(event):
	for i in range(4):
		if event.is_action_pressed("play_%d" %i):
			_check_note_hit(i)


## Check if a note is currently on the hit marker of the given [param track]
func _check_note_hit(track: int):
	var notes = $Notes.get_children().filter(func(note: NoteNode): return note.note.track == track)
	for note: NoteNode in notes:
		if abs(last_position - note.seconds) <= hit_window:
			note.queue_free()
			note_hit.emit(note.note)
		elif last_position - note.seconds > hit_window:
			note_missed.emit(note.note)
