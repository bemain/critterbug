extends Node2D

func _ready() -> void:
	$SongManager.play(Songs.songs[0]) # FIXME: Just for testing
	
	$GUI/AudioLatency/Slider.value = Songs.audio_latency_ms


func _on_latency_slider_value_changed(value: float) -> void:
	Songs.audio_latency_ms = value
	$GUI/AudioLatency/Label.text = "Latency:  %d ms" % value
