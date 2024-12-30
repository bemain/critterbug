extends Node

var instrument_track = load("res://instrument_track.tscn")

# This script should also handle syncing between players when implementing multiplayer

# Temporary test function
func _ready():
	play_song("a")

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

func play_song(title: String) -> Node:
	# Get song somehow
	var song = SongLoader.load_song("res://songs/jazz_swing/jazz_swing.chrp")
	
	_play_track("res://JazzSwing.mp3", 60/song.bpm*song.bpb)
	
	for i in song.instruments:
		var instrument_track = instrument_track.instantiate()
		add_child(instrument_track)
		instrument_track.init(song, i, 60/song.bpm*song.bpb)
	
	return self
