extends Control
## Settings: the audio latency, measured by tapping along to clicks or nudged by hand.

signal back_pressed()

## Calibration plays this many clicks that are not measured, so the player can find the beat...
const LEAD_IN_CLICKS := 2
## ...and then this many that are.
const MEASURED_CLICKS := 8
const CALIBRATION_BPM := 100.0
## A tap further than this from every measured click is not counted.
const MAX_TAP_DISTANCE_S := 0.25
## Calibration needs at least this many counted taps to give a result.
const MIN_TAPS := 4
## Presses closer than this to the previous tap are part of the same tap, such as a trigger's
## stream of motion events.
const MIN_TAP_GAP_S := 0.15

@onready var latency_label: Label = $VBoxContainer/Latency/Value
@onready var calibrate_button: Button = $VBoxContainer/CalibrateButton
@onready var status_label: Label = $VBoxContainer/Status
@onready var result_row: Control = $VBoxContainer/Result
@onready var apply_button: Button = $VBoxContainer/Result/ApplyButton
@onready var clicks: AudioStreamPlayer = $Clicks

var _beat_s := 60.0 / CALIBRATION_BPM
## The positions in the click track at which the player tapped, during calibration.
var _taps: Array[float] = []
## The latency measured by the last calibration, in milliseconds.
var _measured_ms := 0.0


func _ready() -> void:
	clicks.stream = CountIn.make_click_track(CALIBRATION_BPM, LEAD_IN_CLICKS + MEASURED_CLICKS)
	clicks.finished.connect(_finish_calibration)
	visibility_changed.connect(_on_visibility_changed)
	_show_latency()


func _on_visibility_changed() -> void:
	if is_visible_in_tree():
		_show_latency()
		status_label.text = ""
		result_row.hide()
		calibrate_button.grab_focus()
	elif clicks.playing:
		clicks.stop()
		_set_buttons_disabled(false)


func _show_latency() -> void:
	latency_label.text = "%d ms" % roundi(Songs.audio_latency_ms)


func _nudge(step_ms: float) -> void:
	Songs.audio_latency_ms += step_ms
	_show_latency()


func _start_calibration() -> void:
	_taps.clear()
	result_row.hide()
	status_label.text = "Tap any play key on every click, from the third one."
	# A gamepad's A is both a play key and "confirm", so no button may take the taps.
	get_viewport().gui_release_focus()
	_set_buttons_disabled(true)
	clicks.play()


func _input(event: InputEvent) -> void:
	if not clicks.playing:
		return
	for i in range(4):
		if event.is_action_pressed("play_%d" % i):
			get_viewport().set_input_as_handled()
			# The same position source the judging uses, before latency is taken off.
			var position := clicks.get_playback_position() + AudioServer.get_time_since_last_mix()
			if _taps.is_empty() or position - _taps[-1] >= MIN_TAP_GAP_S:
				_taps.append(position)
			return


func _finish_calibration() -> void:
	_set_buttons_disabled(false)
	var offsets := _tap_offsets()
	if offsets.size() < MIN_TAPS:
		status_label.text = "Only %d of %d clicks had a tap on the beat. Try again." % [offsets.size(), MEASURED_CLICKS]
		calibrate_button.grab_focus()
		return
	_measured_ms = roundf(_median(offsets) * 1000)
	status_label.text = "Measured: %d ms" % _measured_ms
	result_row.show()
	apply_button.grab_focus()


## For each measured click, how late the closest tap to it came, in seconds. Clicks with no tap
## close enough are left out, and so are stray taps.
func _tap_offsets() -> Array[float]:
	var offsets: Array[float] = []
	for click in range(LEAD_IN_CLICKS, LEAD_IN_CLICKS + MEASURED_CLICKS):
		var click_s := click * _beat_s
		var closest := INF
		for tap in _taps:
			if absf(tap - click_s) < absf(closest):
				closest = tap - click_s
		if absf(closest) <= MAX_TAP_DISTANCE_S:
			offsets.append(closest)
	return offsets


static func _median(values: Array[float]) -> float:
	var sorted := values.duplicate()
	sorted.sort()
	var middle := sorted.size() / 2
	if sorted.size() % 2 == 1:
		return sorted[middle]
	return (sorted[middle - 1] + sorted[middle]) / 2


func _set_buttons_disabled(disabled: bool) -> void:
	for button: BaseButton in find_children("*", "BaseButton", true, false):
		button.disabled = disabled


func _on_minus_10_pressed() -> void:
	_nudge(-10)


func _on_minus_1_pressed() -> void:
	_nudge(-1)


func _on_plus_1_pressed() -> void:
	_nudge(1)


func _on_plus_10_pressed() -> void:
	_nudge(10)


func _on_calibrate_button_pressed() -> void:
	_start_calibration()


func _on_apply_button_pressed() -> void:
	Songs.audio_latency_ms = _measured_ms
	_show_latency()
	result_row.hide()
	status_label.text = "Saved."
	calibrate_button.grab_focus()


func _on_retry_button_pressed() -> void:
	_start_calibration()


func _on_back_button_pressed() -> void:
	back_pressed.emit()
