extends Node2D

func _ready() -> void:
	var manager := SongManager.instantiate(Songs.songs[0]) # FIXME: Just for testing
	add_child(manager)
