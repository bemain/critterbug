extends Node3D
## The world the band walks in: one area at a time, with exits that lead from one area to the next.
##
## An area is its own scene. Its exits are [AreaExit]s, and its entrances are nodes in the
## [code]area_entrances[/code] group, named so an exit can point at them. When every player stands
## in an exit, the screen fades out, the next area replaces this one, the band appears at the
## matching entrance, and the screen fades back in. The players and their characters stay the same.
##
## [Critter]s in an area can be talked to: a player close to one presses confirm on their own
## device, and the conversation shows in a [DialogueBalloon]. Any player's confirm moves it on and
## any player picks a choice. The band stands still while it lasts, and doesn't travel.
##
## Any player can open the [WorldMenu], except while the band travels or talks. The band stands still
## while it is open. Devices that no player has are ignored.
##
## Run on its own, it spawns one keyboard player and one per connected gamepad, and leaving quits.

## The area the band starts in.
const FIRST_AREA := "res://src/world/World.tscn"
## How long the fade out, and the fade back in, take, in seconds.
const FADE_S := 0.4

const _BALLOON: PackedScene = preload("res://src/ui/dialogue/DialogueBalloon.tscn")

## Emitted when the band has arrived in a new area and the screen has faded back in.
signal arrived(area: Node3D)

## Emitted when the band leaves the world from the [WorldMenu].
signal left()

var area: Node3D
var band: Band

## Covers the screen while the band travels.
var _fade: ColorRect
var _is_travelling := false
## The balloon of the conversation going on, if any.
var _balloon: DialogueBalloon

## Whether the band is in a conversation.
var is_talking: bool:
	get: return _balloon != null

## The open menu, if any.
var _menu: WorldMenu

## Whether the menu is open.
var is_menu_open: bool:
	get: return _menu != null


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
		left.connect(get_tree().quit)


func _physics_process(_delta: float) -> void:
	if _is_travelling or band.characters.is_empty():
		return
	for critter in _critters():
		critter.show_prompt(not is_talking and not is_menu_open and band.characters.any(critter.can_talk_to))
	if is_talking or is_menu_open:
		return
	for exit: AreaExit in get_tree().get_nodes_in_group("area_exits"):
		if area.is_ancestor_of(exit) and exit.holds(band.characters):
			_travel(exit.to_area, exit.to_entrance)
			return


func _input(event: InputEvent) -> void:
	var device := LaneInput.device_of(event)
	if is_talking:
		# The balloon takes input from every device, so keep those outside the band from reaching it.
		if not _is_in_band(device):
			get_viewport().set_input_as_handled()
		return
	if is_menu_open or _is_travelling or not (event is InputEventKey or event is InputEventJoypadButton):
		return
	if event.is_action_pressed("world_menu") and _is_in_band(device):
		get_viewport().set_input_as_handled()
		_open_menu(device)
		return
	if not event.is_action_pressed("ui_accept"):
		return
	for character in band.characters:
		if not character.player.accepts(device):
			continue
		for critter in _critters():
			if critter.can_talk_to(character):
				get_viewport().set_input_as_handled()
				_talk(critter)
				return


## Whether a player in the band has [param device].
func _is_in_band(device: int) -> bool:
	return band.characters.any(func(c: BandCharacter): return c.player.accepts(device))


## Open the menu for [param device]; the band stands still until it closes.
func _open_menu(device: int) -> void:
	band.set_physics_process(false)
	_menu = WorldMenu.new(device)
	_menu.continued.connect(func():
		_menu.queue_free()
		_menu = null
		band.set_physics_process(true))
	_menu.leave_chosen.connect(left.emit)
	add_child(_menu)


## The critters in the current area.
func _critters() -> Array[Critter]:
	var found: Array[Critter] = []
	for critter: Critter in get_tree().get_nodes_in_group("critters"):
		if area.is_ancestor_of(critter):
			found.append(critter)
	return found


## Start [param critter]'s conversation; the band stands still until it ends.
func _talk(critter: Critter) -> void:
	band.set_physics_process(false)
	_balloon = _BALLOON.instantiate()
	add_child(_balloon)
	_balloon.tree_exited.connect(func():
		_balloon = null
		band.set_physics_process(true))
	_balloon.start(critter.dialogue, critter.title, [Story])


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
