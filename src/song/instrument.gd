extends Resource
class_name Instrument

## Human-readable name for this instrument
@export var name: String

## Path to the unique audio for this instrument. 
## Can be an empty string if this instrument doesn't have its own audio.
@export var audio_path: String

## The notes played by this instrument.
@export var notes: Array[Note] = []


## Get the notes played by this instrument on the specifc [param beat].
func notes_in_beat(beat: int) -> Array[Note]:
	return notes.filter(func (note): return note.beat==beat)


func _init(name: String):
	self.name = name

func _to_string() -> String:
	return "Instrument(" + name + ")"
