class_name NoteNode
extends Node2D
## A visual representation of a [Note] on an [InstrumentTrack].

# TODO: Rename


## The scene that uses this script. Used for the [instantiate] method.
const _scene: PackedScene = preload("res://src/song_track/note.tscn")

## Create an instance of this scene, with the given parameters.
static func instantiate(note: Note, track: InstrumentTrack):
	var node = _scene.instantiate()
	node.note = note
	node.track = track
	return node


## Emitted if this note reaches the end of the track without being hit.
signal missed()


## The data for this note.
var note: Note
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
@onready var animation: AnimationPlayer = $AnimationPlayer

## After how many seconds in the song that this note occurs.
var seconds: float: 
	get: return (note.beat + note.subbeat) * track.beat_duration

## The offset on the track in the x-direction.
var x_offset: float:
	get: return (1.5*track.width) - (note.track * track.width)

## Whether this note can be hit.
var is_active: bool = true


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
	var path_point = track.path.curve.sample_baked_with_rotation(track.hit_marker_position * t * track.path.curve.get_baked_length())
	position = path_point.get_origin() + x_offset * path_point.y
	
	if not is_active: return
	
	if song_position > seconds + track.hit_window:
		is_active = false
		missed.emit()
		animation.play("missed")
