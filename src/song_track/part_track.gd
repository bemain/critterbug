class_name PartTrack extends Node2D
## A track that displays the notes played by an [member part] and allows the user to hit them 
## using the keyboard.
## 
## The track only reports what happened; judging and scoring is done by [PerformanceStats].
##
## If the user presses the right key when a note passes the hit marker, [signal note_hit] is emitted
## with how far off the press was. For a sustained note, [signal hold_finished] follows if the user
## holds it to its end.
## If a note passes the hit marker without being hit, [signal note_missed] is emitted.
## If the user presses a key but no note is passing the hit marker, the [signal wrong_note] is emitted.


## Emitted when the user hits a [param note], [param offset_s] seconds from its time (negative is early).
signal note_hit(note: NoteData, offset_s: float)

## Emitted when the user holds a sustained [param note] to its end.
signal hold_finished(note: NoteData)

## Emitted when the user fails to hit a [param note] in time.
signal note_missed(note: NoteData)

## Emitted when the user presses a key but no note is passing the hit marker on that [param track] at that time.
signal wrong_note(beat: float, track: int)


## The part that is playing on this track.
var part: SongPart

## Which of the [member part]'s notes are shown and judged.
var difficulty: Difficulty.Level

## The notes of the [member part] that are shown at the [member difficulty].
var notes: Array[NoteData] = []

var song: Song:
	get: return part.song

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

## Returns the current position in the song, in seconds. Presses are timed with it rather than with
## [member last_position], which is up to a frame old.
var position_source: Callable

@onready var path: Path2D = $Path2D

## The number of seconds off the user can be for a press to be considered a hit.
var hit_window: float = Scoring.GOOD_WINDOW_S

## How much of the track is above the hit marker, as a fraction
var hit_marker_position: float:
	get: return $Visuals.hit_marker_position


func _ready() -> void:
	# Create beat lines
	for i in range(beats):
		var line := Line2D.new()
		line.width = 1.0
		$Beats.add_child(line)


## Reset the track and prepare [param part] for playback at [param difficulty].
func load_song(part: SongPart, difficulty: Difficulty.Level):
	# -INF so that the first update also spawns notes due before the song starts,
	# partway down the track.
	last_position = -INF
	self.part = part
	self.difficulty = difficulty
	notes = part.notes.filter(func(note): return Difficulty.shows(difficulty, note))

## Stop playing: presses are ignored until the next [method load_song].
func unload() -> void:
	part = null
	notes = []


## Move the notes along the track, and create new ones when needed.
## Should be called every frame with [param song_position] as the current position in the [member song]. 
func update(song_position: float) -> void:
	if song_position <= last_position: return  # Can't go backwards
	
	# Add new notes
	var new_notes = notes.filter(func(note): 
		var note_create_at = (note.beat + note.subbeat - beats) * beat_duration
		return last_position < note_create_at and note_create_at <= song_position
	)
	for n in new_notes:
		var note: NoteNode = NoteNode.instantiate(n, self)
		note.missed.connect(func(): note_missed.emit(n))
		note.hit.connect(func(offset_s): note_hit.emit(n, offset_s))
		note.hold_finished.connect(func(): hold_finished.emit(n))
		$Notes.add_child(note)
	
	last_position = song_position
	
	# Update beat lines
	for i: int in range(beats):
		var line: Line2D = $Beats.get_child(i)
		var t = fposmod((song_position / beat_duration + i) / beats, 1)
		var path_point = path.curve.sample_baked_with_rotation(hit_marker_position * t * path.curve.get_baked_length())
		line.set_points(PackedVector2Array([
			path_point.get_origin() + width * 2 * path_point.y,
			path_point.get_origin() - width * 2 * path_point.y,
		]))
	
	# Update notes
	for note: NoteNode in $Notes.get_children():
		note.update(song_position)



func _input(event):
	if part == null:
		return
	for i in range(4):
		if event.is_action_pressed("play_%d" %i):
			_check_note_hit(i)


## Check if a note is currently on the hit marker of the given [param track]
func _check_note_hit(track: int):
	# The audio clock can briefly read behind the last frame; never judge earlier than that.
	var position: float = maxf(position_source.call(), last_position)
	var notes = $Notes.get_children().filter(func(note: NoteNode): return note.is_active and note.note.track == track)
	for note: NoteNode in notes:
		var offset_s := position - note.seconds
		if abs(offset_s) <= hit_window:
			note.register_hit(offset_s)
			return
	
	wrong_note.emit(position / beat_duration, track)
