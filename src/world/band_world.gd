extends Node3D
## The world scene with the band walking in it. Run on its own, it spawns one keyboard player and
## one per connected gamepad.

const _WORLD: PackedScene = preload("res://src/world/World.tscn")

var world: Node3D
var band: Band


func _ready() -> void:
	world = _WORLD.instantiate()
	add_child(world)
	band = Band.new()
	add_child(band)
	if get_tree().current_scene == self:
		band.spawn(Band.local_players())
