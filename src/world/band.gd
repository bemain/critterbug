class_name Band extends Node3D
## The players walking together in the world, with one shared camera that frames them all.
##
## Each player walks a [BandCharacter] with their own device. The camera looks down at a fixed 3/4
## angle at the middle of the band and pulls back as the band spreads out, up to a limit. At that
## limit a player can't walk further from the middle of the band: the part of their step that
## would take them out of the frame is dropped, so they stop at the edge and can still walk along
## it or back.

## The camera's pitch, looking down, in degrees. It is low, so the giant grass reads as a forest.
const CAMERA_PITCH := 35.0
## How far the camera is from the middle of the band when everyone is together, in units.
const MIN_DISTANCE := 5.0
## How far the camera pulls back at most, in units.
const MAX_DISTANCE := 10.0
## How much further back the camera goes for each unit the band spreads out.
const DISTANCE_PER_SPREAD := 1.2
## How far any player may be from the middle of the band, across (x) and in depth (z), in units.
## With the camera at [constant MAX_DISTANCE] this keeps everyone inside the frame.
const MAX_SPREAD := Vector2(4.5, 2.5)
## How quickly the camera follows the band, per second.
const CAMERA_FOLLOW := 5.0

## How far apart the characters stand when they appear, in units.
const SPAWN_SPACING := 0.8

var characters: Array[BandCharacter] = []
var camera: Camera3D


func _ready() -> void:
	camera = Camera3D.new()
	camera.rotation_degrees.x = -CAMERA_PITCH
	add_child(camera)


## Put a character for each of [param players] in a row around [param at], and point the camera at them.
func spawn(players: Array[Player], at := Vector3.ZERO) -> void:
	for character in characters:
		character.queue_free()
	characters.clear()
	for i in players.size():
		var character := BandCharacter.new(players[i])
		character.position = at + Vector3((i - (players.size() - 1) / 2.0) * SPAWN_SPACING, 0, 0)
		add_child(character)
		characters.append(character)
	_frame(1.0)


## The middle of the band on the ground.
func centre() -> Vector3:
	var sum := Vector3.ZERO
	for character in characters:
		sum += character.global_position
	return sum / maxi(characters.size(), 1)


func _physics_process(delta: float) -> void:
	if characters.is_empty():
		return
	var middle := centre()
	for character in characters:
		character.read_input()
		character.walk(_hold_in_frame(character, middle, delta), delta)
	_frame(clampf(CAMERA_FOLLOW * delta, 0.0, 1.0))


## [param character]'s wanted velocity, without the part that would take it further than
## [constant MAX_SPREAD] from [param middle].
func _hold_in_frame(character: BandCharacter, middle: Vector3, delta: float) -> Vector3:
	var velocity := character.wanted_velocity
	var next := character.global_position + velocity * delta - middle
	if absf(next.x) > MAX_SPREAD.x and signf(velocity.x) == signf(next.x):
		velocity.x = 0.0
	if absf(next.z) > MAX_SPREAD.y and signf(velocity.z) == signf(next.z):
		velocity.z = 0.0
	return velocity


## Move the camera [param weight] of the way to where it frames the band.
func _frame(weight: float) -> void:
	var middle := centre()
	var spread := 0.0
	for character in characters:
		var offset := character.global_position - middle
		spread = maxf(spread, maxf(absf(offset.x), absf(offset.z) * MAX_SPREAD.x / MAX_SPREAD.y))
	var distance := clampf(MIN_DISTANCE + spread * DISTANCE_PER_SPREAD, MIN_DISTANCE, MAX_DISTANCE)
	var pitch := deg_to_rad(CAMERA_PITCH)
	var target := middle + Vector3(0, sin(pitch), cos(pitch)) * distance
	camera.global_position = camera.global_position.lerp(target, weight)
