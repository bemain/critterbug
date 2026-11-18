class_name Judge extends RefCounted
## Judges one player's playing of a part, and records the results in [member stats].
##
## It decides which of the part's notes come into play at the player's difficulty, and whether each
## is hit, missed or held, from the player's presses and releases on each lane. It doesn't read
## input or draw anything. Times are positions in the song in seconds, as the player hears it.
##
## Call [method advance] every frame, and [method press] and [method release] as the player's lanes
## go down and up.


## Emitted when [param note] comes into play, [member lead_time_s] before its time.
signal note_entered(note: NoteData)

## Emitted when the player hits [param note].
signal note_hit(note: NoteData, judgement: Scoring.Judgement)

## Emitted when [param note] passes without being hit.
signal note_missed(note: NoteData)

## Emitted when the player holds the sustained [param note] to its end.
signal hold_finished(note: NoteData)

## Emitted when the player lets go of the sustained [param note] before its end.
signal hold_released(note: NoteData)

## Emitted when the player presses [param lane] at [param time_s] and no note is there.
signal wrong_note(lane: int, time_s: float)


## How far from its time a press can be and still hit a note, in seconds.
const HIT_WINDOW_S := Scoring.GOOD_WINDOW_S

## The results so far. Its [member PerformanceStats.difficulty] decides which notes come into play.
var stats: PerformanceStats

## How long before its time a note comes into play, in seconds. A change of difficulty only affects
## notes that haven't come into play yet.
var lead_time_s: float

## Notes in play that haven't been hit or missed yet, in the order they came into play.
var _pending: Array[NoteData] = []

## The sustained note being held on each lane.
var _held: Dictionary[int, NoteData] = {}

## The time of the last [method advance].
var _time_s: float = -INF

var _beat_duration: float


func _init(stats: PerformanceStats, lead_time_s: float) -> void:
	self.stats = stats
	self.lead_time_s = lead_time_s
	_beat_duration = 60.0 / stats.part.song.bpm


## Move the song on to [param time_s]: bring notes into play, finish holds and miss notes that have
## passed. Time never goes backwards; an earlier [param time_s] is ignored.
func advance(time_s: float) -> void:
	if time_s <= _time_s:
		return
	for note: NoteData in stats.part.notes:
		var enters_at := _time_of(note) - lead_time_s
		if _time_s < enters_at and enters_at <= time_s and Difficulty.shows(stats.difficulty, note):
			_pending.append(note)
			note_entered.emit(note)
	_time_s = time_s

	for lane: int in _held.keys():
		if time_s >= _end_of(_held[lane]) - HIT_WINDOW_S:
			_finish_hold(lane)
	for note: NoteData in _pending.duplicate():
		if time_s > _time_of(note) + HIT_WINDOW_S:
			_pending.erase(note)
			stats.record_miss(note)
			note_missed.emit(note)


## The player pressed [param lane] at [param time_s].
func press(lane: int, time_s: float) -> void:
	for note: NoteData in _pending:
		var offset_s := time_s - _time_of(note)
		if note.track == lane and absf(offset_s) <= HIT_WINDOW_S:
			_pending.erase(note)
			var judgement := stats.record_hit(note, offset_s)
			if note.duration > 0:
				_held[lane] = note
			note_hit.emit(note, judgement)
			return
	stats.record_wrong_note(time_s / _beat_duration, lane)
	wrong_note.emit(lane, time_s)


## The player let go of [param lane] at [param time_s].
func release(lane: int, time_s: float) -> void:
	if not _held.has(lane):
		return
	if time_s >= _end_of(_held[lane]) - HIT_WINDOW_S:
		_finish_hold(lane)
		return
	var note: NoteData = _held[lane]
	_held.erase(lane)
	hold_released.emit(note)


func _finish_hold(lane: int) -> void:
	var note: NoteData = _held[lane]
	_held.erase(lane)
	stats.record_hold_finished(note)
	hold_finished.emit(note)


func _time_of(note: NoteData) -> float:
	return (note.beat + note.subbeat) * _beat_duration


func _end_of(note: NoteData) -> float:
	return (note.beat + note.subbeat + note.duration) * _beat_duration
