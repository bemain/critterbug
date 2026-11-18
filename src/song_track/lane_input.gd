class_name LaneInput extends Node
## Reads the [code]play_0[/code] to [code]play_3[/code] actions and reports when each lane goes down
## and comes up, whichever device it comes from.


## Emitted when [param lane] goes down.
signal lane_pressed(lane: int)

## Emitted when [param lane] comes up.
signal lane_released(lane: int)


## How far an analog input, such as a trigger, must go for a lane to go down.
const PRESS_STRENGTH := 0.5
## How far back it must come for the lane to come up again, so a trigger resting near
## [constant PRESS_STRENGTH] does not chatter.
const RELEASE_STRENGTH := 0.3

## Whether each lane is down.
var _lanes_down: Array[bool] = [false, false, false, false]


func _process(_delta: float) -> void:
	# An action can be released without an event, for example when the window loses focus.
	for lane in range(4):
		if _lanes_down[lane] and Input.get_action_raw_strength("play_%d" % lane) < RELEASE_STRENGTH:
			_lanes_down[lane] = false
			lane_released.emit(lane)


func _input(event: InputEvent) -> void:
	for lane in range(4):
		var action := "play_%d" % lane
		if not event.is_action(action):
			continue
		# A trigger sends many motion events while it is pressed, so act on the lane going down or up.
		var threshold := RELEASE_STRENGTH if _lanes_down[lane] else PRESS_STRENGTH
		var is_down := Input.get_action_raw_strength(action) >= threshold
		if is_down == _lanes_down[lane]:
			continue
		_lanes_down[lane] = is_down
		if is_down:
			lane_pressed.emit(lane)
		else:
			lane_released.emit(lane)
