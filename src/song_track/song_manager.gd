@tool
class_name SongManager extends Node2D
## A node responsible for playing a song.
##
## It collects the results from all players, makes sure the audio is in sync with the visuals,
## and updates the playback and score when the players hit or miss notes.
## TODO: This script should also handle syncing between players when implementing multiplayer


## The scene that uses this script. Used for the [instantiate] method.
const _scene: PackedScene = preload("res://src/song_track/SongManager.tscn")

## Create an instance of this scene, with the given parameters.
static func instantiate(song: Song) -> SongManager:
	var manager: SongManager = _scene.instantiate()
	manager.song = song
	return manager


## The track for the instrument that is controlled by the local player
@export var track: InstrumentTrack:
	set(value):
		track = value
		update_configuration_warnings()

## Audio player that handles audio playback for the [member song].
@onready var player: AudioStreamPlayer = $AudioStreamPlayer
var instrument_audio_indices: Dictionary[Instrument, int] = {}



## The current position in the [member song], in seconds.
var song_position: float:
	get: return player.get_playback_position() + AudioServer.get_time_since_last_mix()

## Begin playing a [param song].
func play(song: Song):
	track.song = song
	track.instrument = song.instruments[1] # TODO: Allow selecting instrument
	
	# Prepare audio
	var group := AudioStreamSynchronized.new()
	group.stream_count = song.instruments.size() + 1
	group.set_sync_stream(0, load(song.audio_path))
	for i in range(song.instruments.size()):
		var instrument = song.instruments[i]
		instrument_audio_indices[instrument] = i+1
		var audio = load(instrument.audio_path)
		group.set_sync_stream(i+1, audio)
	player.set_stream(group)
	
	player.play()


func _get_configuration_warnings() -> PackedStringArray:
	if track == null:
		return ["No InstrumentTrack has been assigned."]
	return []


func _ready() -> void:
	if Engine.is_editor_hint(): return
	if track != null:
		track.note_hit.connect(_on_instrument_track_note_hit)
		track.note_missed.connect(_on_instrument_track_note_missed)
		track.wrong_note.connect(_on_instrument_track_wrong_note)


func _process(delta: float) -> void:
	if Engine.is_editor_hint(): return
	track.update(song_position - Songs.audio_latency_ms / 1000)



func _on_instrument_track_note_hit(note: NoteData) -> void:
	print("Hit note: %s" % note)
	# TODO: Keep track of score


func _on_instrument_track_note_missed(note: NoteData) -> void:
	print("Missed note: %s" % note)


func _on_instrument_track_wrong_note(track: int) -> void:
	print("Wrong note on track %d" % track)
