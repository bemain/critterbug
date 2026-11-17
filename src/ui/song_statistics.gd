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
	$VBoxContainer/PercentageHit.text = "%.1f%%" % (stats.fraction_notes_hit*100)
	$VBoxContainer/Score.text = "Score: %d" % stats.score
	$VBoxContainer/LongestCombo.text = "Longest combo: %d" % stats.longest_combo
	var counts := stats.judgement_counts
	$VBoxContainer/Judgements.text = "Perfect %d · Good %d · Miss %d" % [
		counts[Scoring.Judgement.PERFECT],
		counts[Scoring.Judgement.GOOD],
		counts[Scoring.Judgement.MISS],
	]


func _on_back_button_pressed() -> void:
	back_pressed.emit()
