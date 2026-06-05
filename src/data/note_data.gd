class_name NoteData extends Resource

## The track ("lane") that this note belongs to. 
## Count starts on 0.
@export var track: int

## The beat that this note shows up in.
## Count starts on 0.
@export var beat: int
## The offset from the [member beat] that this note lands on.
## For example, a subbeat of [code]0[/code] means the note is "on" the beat, and subbeat of [code]0.5[/code] is halfway betweens the beats.
@export_range(0,1) var subbeat: float

## For how long this note should be pressed. 
## If this is [code]0[/code], the note just has to be hit. If it is greater than [code]0[/code], it has to be sustained for this long.
@export var duration: float = 0

## How important this note is considered for the melodic structure. 
## Lower importance notes are only shown to users on a higher difficulty.
## A note with priority [code]0[/code] is considered of highest importance.
@export var priority: int


func _init(track: int, beat: int, subbeat := 1.0, priority := 0, duration := 0.0):
	self.track = track
	self.beat = beat
	self.subbeat = subbeat
	self.priority = priority
	self.duration = duration

func _to_string() -> String:
	return "Note(priority: %d, track: %d, beat: %.2f" % [priority, track, beat + subbeat] + ("-%.2f)" % (beat + subbeat + duration) if duration != 0 else ")")
