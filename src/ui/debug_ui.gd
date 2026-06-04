extends Control

func _ready() -> void:
	$AudioLatency/Slider.value = Songs.audio_latency_ms


func _process(delta: float) -> void:
	if Input.is_action_just_pressed("debug_toggle_ui"):
		visible = not visible

func _on_latency_slider_value_changed(value: float) -> void:
	Songs.audio_latency_ms = value
	$AudioLatency/Label.text = "Latency:  %d ms" % value
