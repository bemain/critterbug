extends Control

signal back_pressed()


func _ready() -> void:
	visibility_changed.connect(_focus_back)


## Focus the Back button, so a gamepad or the keyboard can leave the screen.
func _focus_back() -> void:
	if is_visible_in_tree():
		$VBoxContainer/BackButton.grab_focus()


## Display the given [param stats].
func load_stats(stats: PerformanceStats):
	var song := stats.part.song
	$VBoxContainer/SongTitle.text = song.title
	$VBoxContainer/InstrumentName.text = stats.part.name
	$VBoxContainer/Difficulty.text = _difficulty_text(stats)
	$VBoxContainer/PercentageHit.text = "%.1f%%" % (stats.fraction_notes_hit*100)
	$VBoxContainer/Score.text = "Score: %d" % stats.score
	$VBoxContainer/LongestCombo.text = "Longest combo: %d" % stats.longest_combo
	var counts := stats.judgement_counts
	$VBoxContainer/Judgements.text = "Perfect %d · Good %d · Miss %d" % [
		counts[Scoring.Judgement.PERFECT],
		counts[Scoring.Judgement.GOOD],
		counts[Scoring.Judgement.MISS],
	]


## The difficulty played: its name, or for Auto the range of levels the song covered.
static func _difficulty_text(stats: PerformanceStats) -> String:
	var lowest: String = Difficulty.Level.keys()[stats.lowest_difficulty].capitalize()
	var highest: String = Difficulty.Level.keys()[stats.highest_difficulty].capitalize()
	if not stats.is_adaptive:
		return highest
	if lowest == highest:
		return "Auto: %s" % highest
	return "Auto: %s to %s" % [lowest, highest]


func _on_back_button_pressed() -> void:
	back_pressed.emit()
