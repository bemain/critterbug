extends Node2D

func _ready() -> void:
	var manager := SongManager.instantiate(Songs.songs[0]) # FIXME: Just for testing
	add_child(manager)
	
	$AudioLatency/Slider.value = Songs.audio_latency_ms


func _on_latency_slider_value_changed(value: float) -> void:
	Songs.audio_latency_ms = value
	$AudioLatency/Label.text = "Latency:  %d ms" % value
