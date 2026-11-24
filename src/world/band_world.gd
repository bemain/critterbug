extends Node3D
## The world the band walks in: one area at a time, with exits that lead from one area to the next.
##
## An area is its own scene. Its exits are [AreaExit]s, and its entrances are nodes in the
## [code]area_entrances[/code] group, named so an exit can point at them. When every player stands
## in an exit, the screen fades out, the next area replaces this one, the band appears at the
## matching entrance, and the screen fades back in. The players and their characters stay the same.
##
## Run on its own, it spawns one keyboard player and one per connected gamepad.

## The area the band starts in.
const FIRST_AREA := "res://src/world/World.tscn"
## How long the fade out, and the fade back in, take, in seconds.
const FADE_S := 0.4

## Emitted when the band has arrived in a new area and the screen has faded back in.
signal arrived(area: Node3D)

var area: Node3D
var band: Band

## Covers the screen while the band travels.
var _fade: ColorRect
var _is_travelling := false


func _ready() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 10
	add_child(layer)
	_fade = ColorRect.new()
	_fade.color = Color(0, 0, 0, 0)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.add_child(_fade)
	band = Band.new()
	add_child(band)
	_load_area(FIRST_AREA)
	if get_tree().current_scene == self:
		band.spawn(Band.local_players())


func _physics_process(_delta: float) -> void:
	if _is_travelling or band.characters.is_empty():
		return
	for exit: AreaExit in get_tree().get_nodes_in_group("area_exits"):
		if area.is_ancestor_of(exit) and exit.holds(band.characters):
			_travel(exit.to_area, exit.to_entrance)
			return


## Fade out, swap to [param scene]'s area, put the band at [param entrance], and fade back in.
func _travel(scene: String, entrance: StringName) -> void:
	_is_travelling = true
	band.set_physics_process(false)
	await create_tween().tween_property(_fade, "color:a", 1.0, FADE_S).finished
	_load_area(scene)
	var marker := _entrance(entrance)
	band.move_to(marker.global_position)
	band.set_physics_process(true)
	await create_tween().tween_property(_fade, "color:a", 0.0, FADE_S).finished
	_is_travelling = false
	arrived.emit(area)


func _load_area(scene: String) -> void:
	if area != null:
		remove_child(area)
		area.queue_free()
	area = load(scene).instantiate()
	add_child(area)
	move_child(area, 0)
	# An area can have a camera of its own, which takes over the view when it enters the tree.
	band.camera.make_current()


func _entrance(entrance_name: StringName) -> Node3D:
	for node: Node3D in get_tree().get_nodes_in_group("area_entrances"):
		if area.is_ancestor_of(node) and node.name == entrance_name:
			return node
	push_error("No entrance named %s in %s" % [entrance_name, area.scene_file_path])
	return area
