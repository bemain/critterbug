extends Node

# TODO: This script should also handle syncing between players when implementing multiplayer

# FIXME: Temporary test function
func _ready():
	play_song(Songs.songs[0])

func _play_track(path: String, delay: float) -> void:
	var stream = load(path)
	var stream_player = AudioStreamPlayer.new()
	add_child(stream_player)
	stream_player.set_stream(stream)
	
	var timer = Timer.new()
	add_child(timer)
	timer.one_shot = true
	timer.wait_time = delay
	
	timer.connect("timeout", stream_player.play)
	timer.start()

func play_song(song: Song) -> Node:
	_play_track("res://songs/jazz_swing/JazzSwing.mp3", song.bpb*60.0/song.bpm)
	
	for i in song.instruments.size():
		var instrument_track = InstrumentTrack.instantiate(song, song.instruments[i], song.bpb*60.0/song.bpm)
		instrument_track.position = Vector2(i*500, 0)
		add_child(instrument_track)
	
	return self
