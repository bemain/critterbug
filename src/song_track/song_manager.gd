extends Node

var instrument_track = load("res://src/song_track/instrument_track.tscn")

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
	
	for i in song.instruments:
		var instrument_track = instrument_track.instantiate()
		add_child(instrument_track)
		instrument_track.init(song, i, song.bpb*60.0/song.bpm)
	
	return self
