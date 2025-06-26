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
	node.timer = -track.beat_duration * note.subbeat
	return node

## The data for this note.
var note: Note
## The track that this belongs to.
var track: InstrumentTrack

## The offset on the track in the x-direction
var x_offset: float:
	get: return (1.5*track.width) - (note.track * track.width)

var timer: float

func _process(delta: float) -> void:
	timer += delta
	var t = timer / (track.beats * track.beat_duration)
	var path_point = track.path.curve.sample_baked_with_rotation(track.hit_marker_position * t * track.path.curve.get_baked_length())
	position = path_point.get_origin() + self.x_offset * path_point.y
	
	if track.beat_length * timer / track.beat_duration >= track.length:
		queue_free()
