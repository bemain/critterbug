class_name Difficulty
## How many of a part's notes the player is shown, chosen by [member NoteData.priority].

## Each level shows the notes with a priority up to and including its value. [constant EXPERT] shows every note.
enum Level { EASY, NORMAL, HARD, EXPERT }


## Whether [param note] is shown at [param level].
static func shows(level: Level, note: NoteData) -> bool:
	return level == Level.EXPERT or note.priority <= level
