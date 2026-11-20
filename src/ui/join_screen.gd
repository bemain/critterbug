class_name JoinScreen extends Control
## Lets each person join the band with their own device, pick a part and a difficulty, and get ready.
##
## A device that hasn't joined joins by pressing confirm or a lane key or button, in the next free
## slot. A joined player changes only their own slot, with their own device: up and down choose a
## field, left and right change it, confirm toggles Ready, and cancel un-readies and then leaves.
## Cancel on a device that hasn't joined goes back to the song list; the players stay joined.
## The song starts as soon as everyone who joined is Ready.

## Emitted when everyone who joined is Ready, with a player for each of them in slot order, numbered
## by their slot.
signal started(players: Array[Player])

## Emitted when a device that hasn't joined presses cancel.
signal back_pressed()

const MAX_PLAYERS := 4

## The difficulties a player can choose, in order; null is Auto.
const DIFFICULTIES: Array = [
	Difficulty.Level.EASY, Difficulty.Level.NORMAL, Difficulty.Level.HARD, Difficulty.Level.EXPERT, null,
]

## The fields of a slot that a player moves between.
enum Field { PART, DIFFICULTY }


## One joined person's choices.
class Slot:
	var device: int
	var part_index := 0
	var difficulty_index := 1
	var field := Field.PART
	var is_ready := false

	func _init(device: int) -> void:
		self.device = device


## The song the players are joining.
var song: Song

## The slot at each position, or null where no one has joined.
var _slots: Array = []

## Pads that disconnected while the screen was hidden, such as during a song. Their slots are
## removed when the screen opens again, unless they reconnect first.
var _disconnected: Dictionary[int, bool] = {}

var _title: Label
var _slot_labels: Array[Label] = []


func _ready() -> void:
	_slots.resize(MAX_PLAYERS)
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var column := VBoxContainer.new()
	column.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	column.grow_horizontal = Control.GROW_DIRECTION_BOTH
	column.grow_vertical = Control.GROW_DIRECTION_BOTH
	column.add_theme_constant_override("separation", 24)
	add_child(column)
	_title = Label.new()
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.add_theme_font_size_override("font_size", 24)
	column.add_child(_title)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 48)
	column.add_child(row)
	for i in MAX_PLAYERS:
		var label := Label.new()
		label.custom_minimum_size = Vector2(200, 0)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		row.add_child(label)
		_slot_labels.append(label)
	Input.joy_connection_changed.connect(_on_joy_connection_changed)
	_refresh()


## Show the screen for [param song], with everyone who already joined not Ready.
func open(song: Song) -> void:
	self.song = song
	for device: int in _disconnected:
		var index := _slot_of(device)
		if index != -1:
			_slots[index] = null
	_disconnected.clear()
	for slot in _slots:
		if slot != null:
			slot.is_ready = false
			slot.part_index = mini(slot.part_index, song.parts.size() - 1)
	_refresh()
	show()


## Remove everyone who joined.
func clear() -> void:
	_slots.fill(null)
	_disconnected.clear()
	_refresh()


func _input(event: InputEvent) -> void:
	if not is_visible_in_tree():
		return
	if not (event is InputEventKey or event is InputEventJoypadButton) or not event.is_pressed() or event.is_echo():
		return
	get_viewport().set_input_as_handled()
	var device := LaneInput.device_of(event)
	var index := _slot_of(device)
	if index == -1:
		if event.is_action("ui_cancel"):
			back_pressed.emit()
		elif event.is_action("ui_accept") or _is_lane(event):
			_join(device)
			_refresh()
		return
	var slot: Slot = _slots[index]
	if event.is_action("ui_cancel"):
		if slot.is_ready:
			slot.is_ready = false
		else:
			_slots[index] = null
	elif event.is_action("ui_accept"):
		slot.is_ready = not slot.is_ready
	elif slot.is_ready:
		pass  # A Ready player's choices stay as they are until they un-ready.
	elif event.is_action("ui_up") or event.is_action("ui_down"):
		slot.field = Field.DIFFICULTY if slot.field == Field.PART else Field.PART
	elif event.is_action("ui_left") or event.is_action("ui_right"):
		var step := -1 if event.is_action("ui_left") else 1
		if slot.field == Field.PART:
			slot.part_index = posmod(slot.part_index + step, song.parts.size())
		else:
			slot.difficulty_index = posmod(slot.difficulty_index + step, DIFFICULTIES.size())
	_refresh()
	_start_if_ready()


func _is_lane(event: InputEvent) -> bool:
	for lane in range(4):
		if event.is_action("play_%d" % lane):
			return true
	return false


func _slot_of(device: int) -> int:
	for i in MAX_PLAYERS:
		if _slots[i] != null and _slots[i].device == device:
			return i
	return -1


func _join(device: int) -> void:
	var free := _slots.find(null)
	if free != -1:
		_slots[free] = Slot.new(device)


func _start_if_ready() -> void:
	var joined := _slots.filter(func(slot): return slot != null)
	if joined.is_empty() or not joined.all(func(slot): return slot.is_ready):
		return
	var players: Array[Player] = []
	for slot: Slot in joined:
		var level = DIFFICULTIES[slot.difficulty_index]
		var is_adaptive: bool = level == null
		var difficulty: Difficulty.Level = Difficulty.ADAPTIVE_START if is_adaptive else level
		var player := Player.new([slot.device], song.parts[slot.part_index], difficulty, is_adaptive)
		player.number = _slots.find(slot) + 1
		players.append(player)
		slot.is_ready = false
	_refresh()
	started.emit(players)


func _on_joy_connection_changed(device: int, connected: bool) -> void:
	if not is_visible_in_tree():
		# A pad that goes away mid-song keeps its player, whose notes then miss until it comes back.
		# If it is still gone when the screen opens again, its slot is removed then.
		if connected:
			_disconnected.erase(device)
		else:
			_disconnected[device] = true
		return
	var index := _slot_of(device)
	if not connected and index != -1:
		_slots[index] = null
		_refresh()


func _refresh() -> void:
	if _title == null:
		return
	_title.text = "%s\nPress a button on your keyboard or gamepad to join" % (song.title if song else "")
	for i in MAX_PLAYERS:
		var slot: Slot = _slots[i]
		if slot == null:
			_slot_labels[i].text = "P%d\n\nPress to join" % (i + 1)
			continue
		var part: String = song.parts[slot.part_index].name.capitalize() if song else ""
		var level = DIFFICULTIES[slot.difficulty_index]
		var difficulty: String = "Auto" if level == null else Difficulty.Level.keys()[level].capitalize()
		_slot_labels[i].text = "P%d\n%s\n\n%s\n%s\n\n%s" % [
			i + 1,
			"Keyboard" if slot.device == LaneInput.KEYBOARD else "Gamepad %d" % (slot.device + 1),
			_field_text(part, slot, Field.PART),
			_field_text(difficulty, slot, Field.DIFFICULTY),
			"READY" if slot.is_ready else "Not ready",
		]


## [param text] with arrows around it if it is the [param slot]'s current field.
func _field_text(text: String, slot: Slot, field: Field) -> String:
	if slot.field == field and not slot.is_ready:
		return "< %s >" % text
	return text
