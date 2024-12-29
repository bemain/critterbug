extends Resource
class_name Instrument

@export var name: String

@export var notes: Array[Note]


func notes_in_beat(beat: int) -> Array[Note]:
	return notes.filter(func (note): note.beat==beat)
