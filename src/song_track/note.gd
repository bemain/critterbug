class_name NoteNode
extends Node2D


# The scene that uses this script. Used for the [instantiate] method.
const _scene: PackedScene = preload("res://src/song_track/note.tscn")

# Create an instance of this scene, with the given parameters.
static func instantiate(path, time_until_hit, track, track_width, spawn_time, offset):
	var note = _scene.instantiate()
	note.path = path
	note.time_until_hit = time_until_hit
	note.timer = offset
	note.track_offset = (1.5*track_width) - (track * track_width)
	return note


var path: Path2D

var time_until_hit: float
var timer: float
var track_offset: float


func _process(delta: float) -> void:
	timer += delta
	var t = timer / time_until_hit
	var path_point = path.curve.sample_baked_with_rotation(t * path.curve.get_baked_length())
	position = path_point.get_origin() + self.track_offset * path_point.y
