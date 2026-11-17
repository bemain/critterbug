class_name Scoring
## Scoring rules: how a hit's timing is judged and what each judgement is worth.

enum Judgement { PERFECT, GOOD, MISS }

## A hit at most this many seconds from the note's time is [constant PERFECT].
const PERFECT_WINDOW_S := 0.03
## A hit at most this many seconds from the note's time is [constant GOOD]. Further away is not a hit.
const GOOD_WINDOW_S := 0.06

## Points for each [enum Judgement].
const POINTS: Dictionary[Judgement, int] = {
	Judgement.PERFECT: 100,
	Judgement.GOOD: 50,
	Judgement.MISS: 0,
}

## Extra points for holding a sustained note to its end.
const HOLD_BONUS := 50

## How many of the most recent judgements the short-term accuracy is computed over.
const RECENT_JUDGEMENTS := 8


## The judgement for a hit [param offset_s] seconds from the note's time (negative is early).
static func judge(offset_s: float) -> Judgement:
	var distance := absf(offset_s)
	if distance <= PERFECT_WINDOW_S:
		return Judgement.PERFECT
	if distance <= GOOD_WINDOW_S:
		return Judgement.GOOD
	return Judgement.MISS
