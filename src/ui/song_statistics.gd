extends Control

signal back_pressed()


## Display the given [param stats].
func load_stats(stats: PerformanceStats):
	var song := stats.part.song
	$VBoxContainer/SongTitle.text = song.title
	$VBoxContainer/InstrumentName.text = stats.part.name
	$VBoxContainer/PercentageHit.text = "%.1f%%" % (stats.fraction_notes_hit*100)
	$VBoxContainer/Score.text = "Score: %d" % stats.score
	var counts := stats.judgement_counts
	$VBoxContainer/Judgements.text = "Perfect %d · Good %d · Miss %d" % [
		counts[Scoring.Judgement.PERFECT],
		counts[Scoring.Judgement.GOOD],
		counts[Scoring.Judgement.MISS],
	]


func _on_back_button_pressed() -> void:
	back_pressed.emit()
