## A node responsible for playing a song.
## It collects the results from all players, makes sure the audio is in sync with the visuals,
## and updates the playback and score when the players hit or miss notes.
class_name SongManager
extends Node

## The scene that uses this script. Used for the [instantiate] method.
const _scene: PackedScene = preload("res://src/song_track/song_manager.tscn")

static func instantiate(song: Song) -> SongManager:
	var manager: SongManager = _scene.instantiate()
	manager.song = song
	return manager


# TODO: This script should also handle syncing between players when implementing multiplayer

var song: Song

## The track for the instrument that is controlled by the local player
@onready var track: InstrumentTrack = $InstrumentTrack

## Audio players for the instruments of the song.
var instrument_players: Dictionary[Instrument, AudioStreamPlayer] = {}


func _ready():
	track.song = song
	track.instrument = song.instruments[0] # TODO: Allow selecting instrument
	
	# Prepare players
	if not song.audio_path.is_empty():
		$Players/Primary.set_stream(load(song.audio_path))
	
	for instrument in song.instruments:
		instrument_players[instrument] = _create_instrument_player(instrument)
	
	# Wait before starting audio playback, so that the audio is in sync with the visuals.
	get_tree().create_timer(track.initial_delay, false).timeout.connect(func(): 
		for player: AudioStreamPlayer in $Players.get_children():
			player.play()
	)
	
	# Start visuals
	track.start()


## Creates an audio player that plays the given [instrument], if it has its own audio.
func _create_instrument_player(instrument: Instrument) -> AudioStreamPlayer:
	if instrument.audio_path.is_empty():
		return null
	
	var player := AudioStreamPlayer.new()
	player.set_stream(load(instrument.audio_path))
	$Players.add_child(player)
	return player
