extends Resource
class_name Note

@export var track: int

@export var beat: int
@export_range(0,1) var subbeat: float

@export var priority: int


func _init(track: int, beat: int, subbeat := 1.0, priority := 0):
	self.track = track
	self.beat = beat
	self.subbeat = subbeat
	self.priority = priority

func _to_string() -> String:
	return "Note(priority: %d, track: %d, beat: %d [%d])" % [priority, track, beat, subbeat] 
