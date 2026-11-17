class_name Difficulty
## How many of a part's notes the player is shown, chosen by [member NoteData.priority].

## Each level shows the notes with a priority up to and including its value. [constant EXPERT] shows every note.
enum Level { EASY, NORMAL, HARD, EXPERT }


## Adaptive difficulty ("Auto") starts here...
const ADAPTIVE_START := Level.NORMAL
## ...goes up a level when the player's recent accuracy is at least this, over a full window...
const RAISE_ACCURACY := 0.9
## ...and down a level when it is at most this.
const LOWER_ACCURACY := 0.5
## After a change, this many more notes must be judged before the next one.
const ADAPTIVE_COOLDOWN := 8


## Whether [param note] is shown at [param level].
static func shows(level: Level, note: NoteData) -> bool:
	return level == Level.EXPERT or note.priority <= level
