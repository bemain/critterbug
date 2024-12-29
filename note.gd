extends Node2D

var speed: float

func init(speed, track, offset):
	self.speed = speed
	position.x = -64 + (64*track)
	position.y = offset
	return self

func _process(delta: float) -> void:
	position.y += delta * speed
