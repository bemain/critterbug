extends Control


@onready var song_manager: SongManager = $"../SongManager"


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$SongSelectionMenu.hide()
	$SongStatistics.hide()
	$SettingsMenu.hide()
	$MainMenu.show()


func _process(_delta: float) -> void:
	$Score.visible = song_manager.playing
	$Combo.visible = song_manager.playing
	var count_in_beat := song_manager.count_in_beat
	$CountIn.visible = count_in_beat > 0
	$CountIn.text = str(count_in_beat)
	if song_manager.playing:
		var stats := song_manager.current_stats
		$Score.text = "Score: %d" % stats.score
		$Combo.text = "Combo: %d  x%d" % [stats.combo, Scoring.multiplier(stats.combo)]


func _on_main_menu_settings_pressed() -> void:
	$MainMenu.hide()
	$SettingsMenu.show()


func _on_settings_menu_back_pressed() -> void:
	$SettingsMenu.hide()
	$MainMenu.show()


func _on_main_menu_freeplay_pressed() -> void:
	$MainMenu.hide()
	$SongSelectionMenu.show()


func _on_song_selection_menu_back_pressed() -> void:
	$SongSelectionMenu.hide()
	$MainMenu.show()


func _on_song_selection_menu_part_selected(part: SongPart, difficulty: Difficulty.Level) -> void:
	$MainMenu.hide()
	$SongSelectionMenu.hide()


func _on_song_manager_song_finished(song: Song) -> void:
	$SongStatistics.load_stats(song_manager.current_stats)
	$SongStatistics.show()


func _on_song_statistics_back_pressed() -> void:
	$SongStatistics.hide()
	$SongSelectionMenu.show()
