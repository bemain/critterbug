class_name MoveInput
## Reads which way a player wants to walk, from their own device only.
##
## The keyboard walks with WASD or the arrow keys; a gamepad with the left stick or the D-pad. The
## bindings are the [code]move_*[/code] actions.

## Below this length a stick's push is ignored, so a resting stick doesn't drift.
const DEADZONE := 0.2


## Which way [param device] is pushed, on the ground plane: x is right, y is towards the camera
## (back). Its length is at most 1.
static func vector(device: int) -> Vector2:
	var push := Vector2(
		LaneInput.action_strength(device, "move_right") - LaneInput.action_strength(device, "move_left"),
		LaneInput.action_strength(device, "move_back") - LaneInput.action_strength(device, "move_forward"),
	)
	if push.length() < DEADZONE:
		return Vector2.ZERO
	return push.limit_length(1.0)
