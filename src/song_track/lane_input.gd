class_name LaneInput extends Node
## Reads the [code]play_0[/code] to [code]play_3[/code] actions and reports when each lane goes down
## and comes up on each input device.
##
## The keyboard is one device, [constant KEYBOARD]; each joypad is its own device, by its device id.


## Emitted when [param lane] goes down on [param device].
signal lane_pressed(device: int, lane: int)

## Emitted when [param lane] comes up on [param device].
signal lane_released(device: int, lane: int)


## The device id of the keyboard. Keyboard events report device 0, the same as the first joypad.
const KEYBOARD := -1

## How far an analog input, such as a trigger, must go for a lane to go down.
const PRESS_STRENGTH := 0.5
## How far back it must come for the lane to come up again, so a trigger resting near
## [constant PRESS_STRENGTH] does not chatter.
const RELEASE_STRENGTH := 0.3

## Which lanes are down on each device that has had a lane down.
var _lanes_down: Dictionary[int, Array] = {}


## The device that [param event] comes from.
static func device_of(event: InputEvent) -> int:
	if event is InputEventJoypadButton or event is InputEventJoypadMotion:
		return event.device
	return KEYBOARD


## How far [param lane] is pressed on [param device], from 0 to 1, over all its bindings.
static func strength(device: int, lane: int) -> float:
	var result := 0.0
	for binding: InputEvent in InputMap.action_get_events("play_%d" % lane):
		if device == KEYBOARD and binding is InputEventKey:
			if Input.is_physical_key_pressed(binding.physical_keycode) or Input.is_key_pressed(binding.keycode):
				result = 1.0
		elif device != KEYBOARD and binding is InputEventJoypadButton:
			if Input.is_joy_button_pressed(device, binding.button_index):
				result = 1.0
		elif device != KEYBOARD and binding is InputEventJoypadMotion:
			result = maxf(result, Input.get_joy_axis(device, binding.axis) * signf(binding.axis_value))
	return result


func _process(_delta: float) -> void:
	# A lane can come up without an event, for example when the window loses focus.
	for device: int in _lanes_down.keys():
		for lane in range(4):
			if _lanes_down[device][lane]:
				_update(device, lane)


func _input(event: InputEvent) -> void:
	for lane in range(4):
		if event.is_action("play_%d" % lane):
			_update(device_of(event), lane)


## Find whether [param lane] went down or came up on [param device], and report it.
func _update(device: int, lane: int) -> void:
	if not _lanes_down.has(device):
		_lanes_down[device] = [false, false, false, false]
	var was_down: bool = _lanes_down[device][lane]
	# A trigger sends many motion events while it is pressed, so act on the lane going down or up.
	var is_down := strength(device, lane) >= (RELEASE_STRENGTH if was_down else PRESS_STRENGTH)
	if is_down == was_down:
		return
	_lanes_down[device][lane] = is_down
	if is_down:
		lane_pressed.emit(device, lane)
	else:
		lane_released.emit(device, lane)
