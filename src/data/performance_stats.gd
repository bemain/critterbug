class_name PerformanceStats extends Resource
## Statistics from playing a [member song].
## TODO: Persist these to disk.

## The id of the song that was played.
var song_id: String

## The name of the instrument that was played.
var instrument_name: String

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
	get: return float(num_notes_hit) / (num_notes_hit + num_notes_missed)


func _init(song: Song, instrument: Instrument):
	self.song_id = song.id
	self.instrument_name = instrument.name


func _to_string() -> String:
	return "PerformanceStats(song: %s)" % [Songs.by_id(song_id)]
