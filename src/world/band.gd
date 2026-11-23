class_name Band extends Node3D
## The players walking together in the world, with one shared camera that frames them all.
##
## Each player walks a [BandCharacter] with their own device. The camera looks down at a fixed 3/4
## angle at the middle of the band (the middle of the box around them) and pulls back as the band
## spreads out, up to a limit. The band can be at most twice [constant MAX_SPREAD] wide and deep:
## the part of a step that would make it wider or deeper than that is dropped, so a player stops
## at the edge and can still walk along it or back. That holds between every two players, whether
## they walk or stand still.

## The camera's pitch, looking down, in degrees. It is low, so the giant grass reads as a forest.
const CAMERA_PITCH := 35.0
## How far the camera is from the middle of the band when everyone is together, in units.
const MIN_DISTANCE := 5.0
## How far the camera pulls back at most, in units.
const MAX_DISTANCE := 10.0
## How much further back the camera goes for each unit the band spreads out.
const DISTANCE_PER_SPREAD := 1.2
## Half the most the band may spread, across (x) and in depth (z), in units. With the camera at
## [constant MAX_DISTANCE] this keeps everyone inside a 16:9 frame; a narrower window keeps the
## same width in view (see [method _fit_view]).
const MAX_SPREAD := Vector2(4.5, 2.5)
## The aspect the spread was tuned for, and the camera's field of view across its height there.
const BASE_ASPECT := 16.0 / 9.0
const BASE_FOV := 75.0
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
	camera.make_current()


## A player for the keyboard and for each connected gamepad, up to four, for running a world scene
## on its own before the join screen leads into it.
static func local_players() -> Array[Player]:
	var players: Array[Player] = [Player.new([LaneInput.KEYBOARD], null, Difficulty.Level.NORMAL)]
	for pad in Input.get_connected_joypads():
		if players.size() < 4:
			players.append(Player.new([pad], null, Difficulty.Level.NORMAL))
	for i in players.size():
		players[i].number = i + 1
	return players


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


## Put the characters in a row around [param at], standing still, and point the camera at them.
func move_to(at: Vector3) -> void:
	for i in characters.size():
		var character := characters[i]
		character.global_position = at + Vector3((i - (characters.size() - 1) / 2.0) * SPAWN_SPACING, 0, 0)
		character.velocity = Vector3.ZERO
	_frame(1.0)


## The middle of the band on the ground: the middle of the box around everyone.
func centre() -> Vector3:
	var box := _box(characters)
	return Vector3((box.position.x + box.end.x) / 2, _height(), (box.position.y + box.end.y) / 2)


## The box around [param some] on the ground, with x across and y in depth (z).
static func _box(some: Array[BandCharacter]) -> Rect2:
	var box := Rect2(Vector2(some[0].global_position.x, some[0].global_position.z), Vector2.ZERO)
	for character in some:
		box = box.expand(Vector2(character.global_position.x, character.global_position.z))
	return box


func _height() -> float:
	var sum := 0.0
	for character in characters:
		sum += character.global_position.y
	return sum / characters.size()


func _physics_process(delta: float) -> void:
	if characters.is_empty():
		return
	for character in characters:
		character.read_input()
		character.walk(_hold_in_frame(character, delta), delta)
	_fit_view()
	_frame(clampf(CAMERA_FOLLOW * delta, 0.0, 1.0))


## [param character]'s wanted velocity, without the part that would take it further than twice
## [constant MAX_SPREAD] from any other character, across or in depth.
func _hold_in_frame(character: BandCharacter, delta: float) -> Vector3:
	var velocity := character.wanted_velocity
	var others := characters.filter(func(c): return c != character)
	if others.is_empty():
		return velocity
	var box := _box(others)
	var next := character.global_position + velocity * delta
	if velocity.x > 0 and next.x > box.position.x + 2 * MAX_SPREAD.x \
			or velocity.x < 0 and next.x < box.end.x - 2 * MAX_SPREAD.x:
		velocity.x = 0.0
	if velocity.z > 0 and next.z > box.position.y + 2 * MAX_SPREAD.y \
			or velocity.z < 0 and next.z < box.end.y - 2 * MAX_SPREAD.y:
		velocity.z = 0.0
	return velocity


## Keep at least the width of the band's 16:9 view in a window that is narrower than 16:9; a wider
## or 16:9 window keeps the height, and so shows more at the sides.
func _fit_view() -> void:
	var size := get_viewport().get_visible_rect().size
	if size.x / size.y < BASE_ASPECT:
		camera.keep_aspect = Camera3D.KEEP_WIDTH
		camera.fov = rad_to_deg(2 * atan(tan(deg_to_rad(BASE_FOV) / 2) * BASE_ASPECT))
	else:
		camera.keep_aspect = Camera3D.KEEP_HEIGHT
		camera.fov = BASE_FOV


## Move the camera [param weight] of the way to where it frames the band.
func _frame(weight: float) -> void:
	var middle := centre()
	var box := _box(characters)
	var spread := maxf(box.size.x, box.size.y * MAX_SPREAD.x / MAX_SPREAD.y) / 2
	var distance := clampf(MIN_DISTANCE + spread * DISTANCE_PER_SPREAD, MIN_DISTANCE, MAX_DISTANCE)
	var pitch := deg_to_rad(CAMERA_PITCH)
	var target := middle + Vector3(0, sin(pitch), cos(pitch)) * distance
	camera.global_position = camera.global_position.lerp(target, weight)
