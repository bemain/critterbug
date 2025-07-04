@tool
extends Node2D
## Updates the visuals of the [InstrumentTrack] to follow the [member path].

@export var resolution: int = 10:
	set(value):
		resolution = value
		update_lines()
@export_range(0,1) var hit_marker_position: float = 0.8:
	set(value):
		hit_marker_position = value
		update_lines()
@export var width:float = 64:
	set(value):
		width = value
		update_lines()

@onready var track: Node = $"../"
@onready var path: Path2D = $"../Path2D"
@onready var vert_lines: Array[Node] = $Dividers.get_children()
@onready var hit_marker: Node = $HitMarker

func _ready():
	path.curve.connect("changed", update_lines)


## Update the vertical lines and the hit marker to match the [member path].
func update_lines() -> void:
	if not track: return
	
	for line_index in range(vert_lines.size()):
		var new_points = []
		for i in range(resolution):
			var t = float(i) / (resolution-1)
			var point_on_path = path.curve.sample_baked_with_rotation(t * path.curve.get_baked_length())
			new_points.append(point_on_path.get_origin() + (-(2*width) + line_index * width)*point_on_path.y)
		vert_lines[line_index].set_points(PackedVector2Array(new_points))
	
	var hit_marker_path_point = path.curve.sample_baked_with_rotation(hit_marker_position * path.curve.get_baked_length())
	hit_marker.set_points(PackedVector2Array([
		hit_marker_path_point.get_origin() + width * 3 * hit_marker_path_point.y,
		hit_marker_path_point.get_origin() - width * 3 * hit_marker_path_point.y
	]))
