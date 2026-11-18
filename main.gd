extends Node2D


func _on_song_selection_menu_part_selected(part: SongPart, difficulty: Difficulty.Level, is_adaptive: bool) -> void:
	$SongManager.play(part, difficulty, is_adaptive)
