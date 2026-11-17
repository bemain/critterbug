@tool
class_name SongManager extends Node2D
## A node responsible for playing a song.
##
## It collects the results from all players, makes sure the audio is in sync with the visuals,
## and updates the playback and score when the players hit or miss notes.
## TODO: This script should also handle syncing between players when implementing multiplayer

## Emitted when a [param song] has finished playing.
signal song_finished(song: Song)

## The track for the part that is controlled by the local player
@export var track: PartTrack:
	set(value):
		track = value
		update_configuration_warnings()

## Audio player that handles audio playback for the [member song].
@onready var player: AudioStreamPlayer = $AudioStreamPlayer
var part_audio_indices: Dictionary[SongPart, int] = {}


## The song currently played, if any
var current_song: Song

## The statistics of the current playthough of the [member current_song].
var current_stats: PerformanceStats

## Whether a song is currently being played
var playing: bool:
	get: return current_song != null

## The current position in the [member current_song], in seconds.
var song_position: float:
	get: return player.get_playback_position() + AudioServer.get_time_since_last_mix()

## Begin playing the song that [param part] belongs to, with [param part] on the [member track] at [param difficulty].
func play(part: SongPart, difficulty: Difficulty.Level):
	var song := part.song
	track.load_song(part, difficulty)
	
	current_song = song
	current_stats = PerformanceStats.new(part)
	
	# Prepare audio
	var group := AudioStreamSynchronized.new()
	group.stream_count = song.parts.size() + 1
	group.set_sync_stream(0, load(song.audio_path))
	for i in range(song.parts.size()):
		var song_part = song.parts[i]
		part_audio_indices[song_part] = i+1
		var audio = load(song_part.audio_path)
		group.set_sync_stream(i+1, audio)
	player.set_stream(group)
	
	player.play()


func _get_configuration_warnings() -> PackedStringArray:
	if track == null:
		return ["No PartTrack has been assigned."]
	return []


func _ready() -> void:
	if Engine.is_editor_hint(): return
	
	track.note_hit.connect(_on_part_track_note_hit)
	track.note_missed.connect(_on_part_track_note_missed)
	track.hold_finished.connect(_on_part_track_hold_finished)
	track.wrong_note.connect(_on_part_track_wrong_note)


func _process(delta: float) -> void:
	if Engine.is_editor_hint(): return
	
	if player.playing:
		track.visible = true
		track.update(song_position - Songs.audio_latency_ms / 1000)
	else:
		track.visible = false



func _on_part_track_note_hit(note: NoteData, offset_s: float) -> void:
	current_stats.record_hit(note, offset_s)


func _on_part_track_note_missed(note: NoteData) -> void:
	current_stats.record_miss(note)


func _on_part_track_hold_finished(note: NoteData) -> void:
	current_stats.record_hold_finished(note)


func _on_part_track_wrong_note(beat: float, track: int) -> void:
	current_stats.record_wrong_note(beat, track)


func _on_player_finished() -> void:
	song_finished.emit(current_song)
	current_song = null
	# TODO: Save stats
