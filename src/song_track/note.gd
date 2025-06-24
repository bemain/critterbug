extends Node2D

var path: Path2D

var time_until_hit: float
var timer: float
var track_offset: float

func init(path, time_until_hit, track, track_width, spawn_time, offset):
	self.path = path
	self.time_until_hit = time_until_hit
	timer = offset
	self.track_offset = (1.5*track_width) - (track * track_width)
	return self

func _process(delta: float) -> void:
	timer += delta
	var t = timer / time_until_hit
	var path_point = path.curve.sample_baked_with_rotation(t * path.curve.get_baked_length())
	position = path_point.get_origin() + self.track_offset * path_point.y
