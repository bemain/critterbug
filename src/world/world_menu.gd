class_name WorldMenu extends CanvasLayer
## The small menu in the world: Continue, or Leave. It shows above everything else, also a conversation.
##
## Only the device that opened it drives it: up and down choose, confirm picks, and cancel or the
## button that opened it continues. It swallows every other device's presses while it is open. If
## the opener's gamepad disconnects it continues, so nobody is stuck in it.

## Emitted when the band goes on in the world.
signal continued()
## Emitted when the band leaves the world.
signal leave_chosen()

const CHOICES: Array[String] = ["Continue", "Leave"]

## The device that opened the menu.
var device: int

var _selected := 0
var _labels: Array[Label] = []


func _init(device: int) -> void:
	self.device = device
	layer = 110  # The dialogue balloon is at 100.


func _ready() -> void:
	var centre := CenterContainer.new()
	centre.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(centre)
	var panel := PanelContainer.new()
	centre.add_child(panel)
	var margin := MarginContainer.new()
	for side in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 32)
	panel.add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 16)
	margin.add_child(column)
	for choice in CHOICES:
		var label := Label.new()
		label.custom_minimum_size = Vector2(200, 0)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 30)
		column.add_child(label)
		_labels.append(label)
	Input.joy_connection_changed.connect(_on_joy_connection_changed)
	_refresh()


func _input(event: InputEvent) -> void:
	if not (event is InputEventKey or event is InputEventJoypadButton):
		return
	get_viewport().set_input_as_handled()
	if LaneInput.device_of(event) != device or not event.is_pressed() or event.is_echo():
		return
	if event.is_action("world_menu") or event.is_action("ui_cancel"):
		_close(continued)
	elif event.is_action("ui_accept"):
		_close(leave_chosen if _selected == 1 else continued)
	elif event.is_action("ui_up") or event.is_action("ui_down"):
		_selected = 1 - _selected
		_refresh()


func _on_joy_connection_changed(changed_device: int, connected: bool) -> void:
	if changed_device == device and not connected:
		_close(continued)


## Take no more input, and report [param outcome].
func _close(outcome: Signal) -> void:
	set_process_input(false)
	Input.joy_connection_changed.disconnect(_on_joy_connection_changed)
	outcome.emit()


func _refresh() -> void:
	for i in CHOICES.size():
		_labels[i].text = "< %s >" % CHOICES[i] if i == _selected else CHOICES[i]
