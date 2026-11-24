extends Node2D

const _WORLD_SCENE := "res://src/world/BandWorld.tscn"


## Put [param players] in the world. It is loaded when the band enters and freed when they leave, so
## nothing of it renders or runs behind the menus and songs.
func _on_ui_story_started(players: Array[Player]) -> void:
	var world: Node3D = load(_WORLD_SCENE).instantiate()
	add_child(world)
	world.left.connect(func():
		world.queue_free()
		$UI.leave_story())
	world.band.spawn(players)
