extends Node

# TODO: This script should also handle syncing between players when implementing multiplayer

# FIXME: Temporary test function
func _ready():
	play_song(Songs.songs[0])

func play_song(song: Song) -> Node:
	$AudioStreamPlayer.set_stream(load(song.audio_path))
	
	var tracks = []
	for i in song.instruments.size():
		var track = InstrumentTrack.instantiate(song, song.instruments[i])
		track.position = Vector2(i*500, 0)
		#track.beats = 4 + 4*i# FIXME: Just testing
		tracks.append(track)
		add_child(track)
	
	# The number of beats we have to wait before starting audio playback, so that the audio is in sync with the visuals.
	var initial_delay: float = tracks.map(func(track): return track.initial_delay).max()
	get_tree().create_timer(initial_delay, false).timeout.connect(func(): 
		$AudioStreamPlayer.play()
	)
	for track in tracks:
		track.start(initial_delay)
	
	return self
