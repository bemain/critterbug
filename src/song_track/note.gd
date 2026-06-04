class_name NoteNode extends Node2D
## A visual representation of a [NoteData] on an [InstrumentTrack].

# TODO: Rename


## The scene that uses this script. Used for the [instantiate] method.
const _scene: PackedScene = preload("res://src/song_track/Note.tscn")

## Create an instance of this scene, with the given parameters.
static func instantiate(note: NoteData, track: InstrumentTrack):
	var node = _scene.instantiate()
	node.note = note
	node.track = track
	return node


## Emitted if this note reaches the end of the track without being hit.
signal missed()

## Emitted if the user presses the right key when this note is passing the hit marker, 
## and holds it down for the note's entire duration.
signal hit()

## Emitted when the user starts holding down this note, if this is a sustained note.
signal sustain_started()


## The data for this note.
var note: NoteData
## The track that this belongs to.
var track: InstrumentTrack

## The textures used for the note, depending on which track it is on.
const textures: Array = [
	preload("res://src/song_track/assets/square.png"),
	preload("res://src/song_track/assets/triangle.png"),
	preload("res://src/song_track/assets/circle.png"),
	preload("res://src/song_track/assets/pentagon.png"),
]


@onready var sprite: Sprite2D = $Sprite2D
@onready var sustain_line: Line2D = $SustainLine

## After how many seconds in the song that this note occurs.
var seconds: float: 
	get: return (note.beat + note.subbeat) * track.beat_duration

## The offset on the track in the x-direction.
var x_offset: float:
	get: return (1.5*track.width) - (note.track * track.width)

const sustain_line_resolution: int = 10

## Whether this note hasn't passed the hit line.
var is_active: bool = true

## Whether this note is currently being held down by the user.
## This is always [code]false[/code] if this note isn't a sustained note.
var is_held_down: bool = false

## At how many seconds in the song the sustain the sustain line should start.
## This is used to "cut off" the sustain line at the hit marker when this note is being held down.
@onready var sustain_start: float = seconds


func _ready() -> void:
	sprite.texture = textures[note.track]
	sprite.scale = Vector2(0.2, 0.2)


## Move this note to the correct position along the [member track], and remove it if it has reached 
## the end.
func update(song_position: float) -> void:
	## How many beats it is between the current beat and when this note is played.
	## This is negative before the note is played, close to 0 when the note can be hit, and positive
	## when the note has passed the hit marker.
	var beats_from_hit = (song_position - seconds) / track.beat_duration
	var t = beats_from_hit / track.beats + 1
	var path_point := track.path.curve.sample_baked_with_rotation(track.hit_marker_position * t * track.path.curve.get_baked_length())
	position = path_point.get_origin() + x_offset * path_point.y
	
	if note.duration > 0:
		if is_held_down:
			if Input.is_action_pressed("play_%d" % note.track):
				# Cut off the sustain line at the current position
				sustain_start = song_position
			else:
				# The user let go too early
				is_held_down = false
				missed.emit()
				$SustainLine/AnimationPlayer.play("missed")
			if beats_from_hit >= note.duration - track.hit_window:
				# The user held the entire sustain
				sustain_start = seconds + note.duration * track.beat_duration # Make the sustain line 0 in length
				is_held_down = false
				hit.emit()
		
		# Update sustain line
		var start = (song_position - sustain_start) / (track.beat_duration * track.beats) + 1 # Start (bottom) of the sustain line
		var end = t - note.duration / track.beats # End (top) of the sustain line
		var new_points = []
		for i in range(sustain_line_resolution+1):
			var s = start - (start - end) * i / sustain_line_resolution
			path_point = track.path.curve.sample_baked_with_rotation(track.hit_marker_position * s * track.path.curve.get_baked_length())
			new_points.append(path_point.get_origin() + x_offset * path_point.y - position)
		sustain_line.set_points(PackedVector2Array(new_points))
	
	if is_active and song_position > seconds + track.hit_window:
		register_miss()
	
	if beats_from_hit >= note.duration + track.beats * (1 / track.hit_marker_position - 1):
		# Neither the notehead nor the sustain line is visible any longer
		queue_free()


func register_hit():
	is_active = false
	if note.duration > 0:
		is_held_down = true
		sustain_started.emit()
	else:
		hit.emit()
	$Sprite2D/AnimationPlayer.play("hit")

func register_miss():
	is_active = false
	missed.emit()
	$Sprite2D/AnimationPlayer.play("missed")
	$SustainLine/AnimationPlayer.play("missed")
