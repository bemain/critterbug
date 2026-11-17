class_name PerformanceStats extends Resource
## Statistics from playing a [member song].
## TODO: Persist these to disk.

## The part that was played.
var part: SongPart

## The difficulty being played. If [member is_adaptive], it changes during the song.
var difficulty: Difficulty.Level

## Whether the [member difficulty] adapts to how well the player does, following the rules in
## [Difficulty].
var is_adaptive := false

## The lowest and highest [member difficulty] played during the song.
var lowest_difficulty: Difficulty.Level
var highest_difficulty: Difficulty.Level

## How many notes have been judged since the [member difficulty] last changed.
var _judgements_since_change := 0

## Notes that the user hit.
var hit_notes: Array[NoteData] = []

## Notes that the user missed.
var missed_notes: Array[NoteData] = []

## Excessive notes that the user played when they were not intended to be played.
##
## The key is the beat that the note was played, and the value is the track it
## was played on.
var wrong_notes: Dictionary[float, int] = {}

## The total score, following the rules in [Scoring].
var score: int = 0

## How many notes have been hit in a row. A miss resets it; a wrong press does not.
var combo: int = 0

## The highest [member combo] reached.
var longest_combo: int = 0

## How many notes got each [enum Scoring.Judgement].
var judgement_counts: Dictionary[Scoring.Judgement, int] = {
	Scoring.Judgement.PERFECT: 0,
	Scoring.Judgement.GOOD: 0,
	Scoring.Judgement.MISS: 0,
}

## The most recent judgements, oldest first, at most [constant Scoring.RECENT_JUDGEMENTS] of them.
var recent_judgements: Array[Scoring.Judgement] = []

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

## The fraction of the [member recent_judgements] that were hits, or 0 if there are none yet.
var recent_accuracy: float:
	get:
		if recent_judgements.is_empty():
			return 0.0
		var hits := recent_judgements.filter(func(j): return j != Scoring.Judgement.MISS).size()
		return float(hits) / recent_judgements.size()


func _init(part: SongPart, difficulty := Difficulty.Level.EXPERT, is_adaptive := false):
	self.part = part
	self.difficulty = difficulty
	self.is_adaptive = is_adaptive
	lowest_difficulty = difficulty
	highest_difficulty = difficulty


## Record that [param note] was hit [param offset_s] seconds from its time, and return its judgement.
func record_hit(note: NoteData, offset_s: float) -> Scoring.Judgement:
	var judgement := Scoring.judge(offset_s)
	if judgement == Scoring.Judgement.MISS:
		record_miss(note)
		return judgement
	hit_notes.append(note)
	_record_judgement(judgement)
	return judgement


## Record that [param note] passed without being hit.
func record_miss(note: NoteData) -> void:
	missed_notes.append(note)
	_record_judgement(Scoring.Judgement.MISS)


## Record that the sustained [param note] was held to its end.
func record_hold_finished(note: NoteData) -> void:
	score += Scoring.HOLD_BONUS * Scoring.multiplier(combo)


## Record a press on [param track] at [param beat] when no note was there.
func record_wrong_note(beat: float, track: int) -> void:
	wrong_notes[beat] = track


func _record_judgement(judgement: Scoring.Judgement) -> void:
	if judgement == Scoring.Judgement.MISS:
		combo = 0
	else:
		combo += 1
		longest_combo = maxi(longest_combo, combo)
	score += Scoring.POINTS[judgement] * Scoring.multiplier(combo)
	judgement_counts[judgement] += 1
	recent_judgements.append(judgement)
	if recent_judgements.size() > Scoring.RECENT_JUDGEMENTS:
		recent_judgements.pop_front()
	_adapt_difficulty()


func _adapt_difficulty() -> void:
	if not is_adaptive:
		return
	_judgements_since_change += 1
	if _judgements_since_change < Difficulty.ADAPTIVE_COOLDOWN or recent_judgements.size() < Scoring.RECENT_JUDGEMENTS:
		return
	var level := difficulty
	if recent_accuracy >= Difficulty.RAISE_ACCURACY:
		level = mini(difficulty + 1, Difficulty.Level.EXPERT) as Difficulty.Level
	elif recent_accuracy <= Difficulty.LOWER_ACCURACY:
		level = maxi(difficulty - 1, Difficulty.Level.EASY) as Difficulty.Level
	if level == difficulty:
		return
	difficulty = level
	_judgements_since_change = 0
	lowest_difficulty = mini(lowest_difficulty, level) as Difficulty.Level
	highest_difficulty = maxi(highest_difficulty, level) as Difficulty.Level


func _to_string() -> String:
	return "PerformanceStats(part: %s)" % [part]
