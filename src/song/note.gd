extends Resource
class_name Note

## The track ("lane") that this note belongs to. 
## Count starts on 0.
@export var track: int

## The beat that this note shows up in.
## Count starts on 0.
@export var beat: int
## The offset from the [member beat] that this note lands on.
## For example, a subbeat of [code]0[/code] means the note is "on" the beat, and subbeat of [code]0.5[/code] is halfway betweens the beats.
@export_range(0,1) var subbeat: float

## How important this note is considered for the melodic structure. 
## Lower importance notes are only shown to users on a higher difficulty.
## A note with priority [code]0[/code] is considered of highest importance.
@export var priority: int


func _init(track: int, beat: int, subbeat := 1.0, priority := 0):
	self.track = track
	self.beat = beat
	self.subbeat = subbeat
	self.priority = priority

func _to_string() -> String:
	return "Note(priority: %d, track: %d, beat: %.2f)" % [priority, track, beat + subbeat] 
