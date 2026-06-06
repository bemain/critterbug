class_name SongPart extends Resource
## A part of a [member song] belonging to a specific instrument, containing a set of [member notes].

## The unique identifier of this part.
## This is persistent across reboots.
var id: String:
	get: return song.id + "." + name.sha256_text()

## The song that this is part of.
@export var song: Song

## Human-readable name for this part.
@export var name: String

## Path to the unique audio for this part. 
## Can be an empty string if this part doesn't have its own audio.
@export var audio_path: String

## The notes played by this part.
@export var notes: Array[NoteData] = []


## Get the notes played by this part on the specifc [param beat].
func notes_in_beat(beat: int) -> Array[NoteData]:
	return notes.filter(func (note): return note.beat==beat)


func _init(song: Song, name: String):
	self.song = song
	self.name = name

func _to_string() -> String:
	return "SongPart(" + name + ")"
