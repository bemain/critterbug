extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$SongSelectionMenu.hide()
	$SongStatistics.hide()
	$MainMenu.show()


func _on_main_menu_freeplay_pressed() -> void:
	$MainMenu.hide()
	$SongSelectionMenu.show()


func _on_song_selection_menu_back_pressed() -> void:
	$SongSelectionMenu.hide()
	$MainMenu.show()


func _on_song_selection_menu_part_selected(part: SongPart) -> void:
	$MainMenu.hide()
	$SongSelectionMenu.hide()


func _on_song_manager_song_finished(song: Song) -> void:
	$SongStatistics.load_stats($"../SongManager".current_stats)
	$SongStatistics.show()


func _on_song_statistics_back_pressed() -> void:
	$SongStatistics.hide()
	$SongSelectionMenu.show()
