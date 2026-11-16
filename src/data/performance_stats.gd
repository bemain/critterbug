class_name PerformanceStats extends Resource
## Statistics from playing a [member song].
## TODO: Persist these to disk.

## The part that was played.
var part: SongPart

## Notes that the user hit.
var hit_notes: Array[NoteData] = []

## Notes that the user missed.
var missed_notes: Array[NoteData] = []

## Excessive notes that the user played when they were not intended to be played.
##
## The key is the beat that the note was played, and the value is the track it 
## was played on.
var wrong_notes: Dictionary[float, int] = {}

## The number of notes the user hit.
var num_notes_hit: int:
	get: return hit_notes.size()

## The number of notes the user missed.
var num_notes_missed: int:
	get: return missed_notes.size()

## The fraction of the total notes that the user hit.
var fraction_notes_hit: float:
	get:
		var num_notes := num_notes_hit + num_notes_missed
		if num_notes == 0:
			return 0.0
		return float(num_notes_hit) / num_notes


func _init(part: SongPart):
	self.part = part


func _to_string() -> String:
	return "PerformanceStats(part: %s)" % [part]
