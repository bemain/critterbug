class_name NoteNode extends Node2D
## A visual representation of a [NoteData] on an [PartTrack].

# TODO: Rename


## The scene that uses this script. Used for the [instantiate] method. It is loaded when first
## needed, not preloaded: the scene refers to this script, so a preload here would be a cycle.
const _SCENE_PATH := "res://src/song_track/Note.tscn"

## Create an instance of this scene, with the given parameters.
static func instantiate(note: NoteData, track: PartTrack):
	var node = load(_SCENE_PATH).instantiate()
	node.note = note
	node.track = track
	return node


## The data for this note.
var note: NoteData
## The track that this belongs to.
var track: PartTrack

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

## Whether this note is shown as being held down.
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
			# Cut off the sustain line at the current position
			sustain_start = song_position
		
		# Update sustain line
		var start = (song_position - sustain_start) / (track.beat_duration * track.beats) + 1 # Start (bottom) of the sustain line
		var end = t - note.duration / track.beats # End (top) of the sustain line
		var new_points = []
		for i in range(sustain_line_resolution+1):
			var s = start - (start - end) * i / sustain_line_resolution
			path_point = track.path.curve.sample_baked_with_rotation(track.hit_marker_position * s * track.path.curve.get_baked_length())
			new_points.append(path_point.get_origin() + x_offset * path_point.y - position)
		sustain_line.set_points(PackedVector2Array(new_points))
	
	if beats_from_hit >= note.duration + track.beats * (1 / track.hit_marker_position - 1):
		# Neither the notehead nor the sustain line is visible any longer
		queue_free()


## Show that this note was hit, and is being held if it is a sustained note.
func show_hit() -> void:
	is_held_down = note.duration > 0
	$Sprite2D/AnimationPlayer.play("hit")


## Show that this note was missed.
func show_miss() -> void:
	$Sprite2D/AnimationPlayer.play("missed")
	$SustainLine/AnimationPlayer.play("missed")


## Show that this sustained note was held to its end.
func show_hold_finished() -> void:
	is_held_down = false
	sustain_start = seconds + note.duration * track.beat_duration # Make the sustain line 0 in length


## Show that this sustained note was let go of before its end.
func show_hold_released() -> void:
	is_held_down = false
	$SustainLine/AnimationPlayer.play("missed")
