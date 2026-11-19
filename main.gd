extends Node2D


func _on_song_selection_menu_part_selected(part: SongPart, difficulty: Difficulty.Level, is_adaptive: bool) -> void:
	# Until players can join, the one player plays with every device.
	var players: Array[Player] = [Player.new([Player.ANY_DEVICE], part, difficulty, is_adaptive)]
	$SongManager.play(players)
