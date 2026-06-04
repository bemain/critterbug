extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$SongSelectionMenu.hide()
	$MainMenu.show()


func _on_main_menu_freeplay_pressed() -> void:
	$MainMenu.hide()
	$SongSelectionMenu.show()


func _on_song_selection_menu_back_pressed() -> void:
	$SongSelectionMenu.hide()
	$MainMenu.show()


func _on_song_selection_menu_song_selected(song: Song) -> void:
	$MainMenu.hide()
	$SongSelectionMenu.hide()


func _on_song_manager_song_finished(song: Song) -> void:
	$SongSelectionMenu.show()
