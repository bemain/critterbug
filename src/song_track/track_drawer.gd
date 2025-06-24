@tool
extends Node2D

@export var resolution: int = 10:
	set(value):
		resolution = value
		update_lines()
@export var hit_marker_position: float = 0.9:
	set(value):
		hit_marker_position = value
		update_lines()
@export var width:float = 64:
	set(value):
		width = value
		update_lines()

@onready var track: Node = $"../"
@onready var path: Path2D = $"../Path2D"
@onready var lines: Array[Node] = get_children().slice(0, -1)
@onready var hit_marker: Node = get_child(-1)

func _ready():
	path.curve.connect("changed", update_lines)
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func update_lines() -> void:
	if not track: return
	
	for l in range(lines.size()):
		var new_points = []
		for i in range(resolution):
			var t = float(i) / (resolution-1)
			var point_on_path = path.curve.sample_baked_with_rotation(t * path.curve.get_baked_length())
			new_points.append(point_on_path.get_origin() + (-(2*width) + l * width)*point_on_path.y)
		lines[l].set_points(PackedVector2Array(new_points))
	
	var hit_marker_path_point = path.curve.sample_baked_with_rotation(hit_marker_position * path.curve.get_baked_length())
	hit_marker.set_points(PackedVector2Array([
		hit_marker_path_point.get_origin() + width * 3 * hit_marker_path_point.y,
		hit_marker_path_point.get_origin() - width * 3 * hit_marker_path_point.y
	]))
