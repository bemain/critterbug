class_name PerformanceStats extends Resource
## Statistics from playing a [member song].
## TODO: Persist these to disk.

## The song that was played.
var song: Song

## Notes that the user hit.
var notes_hit: Array[NoteData] = []

## Notes that the user missed.
var notes_missed: Array[NoteData] = []

## Excessive notes that the user played when they were not intended to be played.
##
## The key is the beat that the note was played, and the value is the track it 
## was played on.
var wrong_notes: Dictionary[float, int] = {}

func _init(song: Song):
	self.song = song


func _to_string() -> String:
	return "PerformanceStats(song: %s)" % [song]
