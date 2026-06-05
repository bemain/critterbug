extends Node2D


func _on_song_selection_menu_song_selected(song: Song) -> void:
	$SongManager.play(song)
