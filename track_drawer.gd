@tool
extends Node2D

@export var resolution: int = 10

var track: Node
var path: Path2D
var lines: Array[Node]

func _ready():
	track = $"../"
	path = $"../Path2D"
	lines = get_children()
	
	path.curve.connect("changed", update_lines)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func update_lines() -> void:
	for l in range(lines.size()):
		var new_points = []
		for i in range(resolution):
			var t = float(i) / (resolution-1)
			var point_on_path = path.curve.sample_baked_with_rotation(t * path.curve.get_baked_length())
			new_points.append(point_on_path.get_origin() + (-(2*track.width) + l * track.width)*point_on_path.y)
		lines[l].set_points(PackedVector2Array(new_points))
			
