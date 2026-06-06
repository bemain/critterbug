extends Control

signal back_pressed()


## Display the given [param stats].
func load_stats(stats: PerformanceStats):
	var song := Songs.by_id(stats.song_id)
	$VBoxContainer/SongTitle.text = song.title
	$VBoxContainer/InstrumentName.text = stats.instrument_name
	$VBoxContainer/PercentageHit.text = "%.1f%%" % (stats.fraction_notes_hit*100)


func _on_back_button_pressed() -> void:
	back_pressed.emit()
