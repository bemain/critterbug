@tool
class_name SongManager extends Node2D
## A node responsible for playing a song.
##
## It collects the results from all players, makes sure the audio is in sync with the visuals,
## and updates the playback and score when the players hit or miss notes.
## TODO: This script should also handle syncing between players when implementing multiplayer

## Emitted when a [param song] has finished playing.
signal song_finished(song: Song)

## How long a part's audio takes to fade out after a miss, or back in after a hit, in seconds.
const MUTE_FADE_S := 0.05

## The track for the part that is controlled by the local player
@export var track: PartTrack:
	set(value):
		track = value
		update_configuration_warnings()

## Audio player for the [member current_song]'s backing track. The song's time follows it.
@onready var player: AudioStreamPlayer = $AudioStreamPlayer

## One audio player per part of the [member current_song], so each part can be faded on its own.
## A player's volume is ramped per sample within each mix step, which keeps the fades free of clicks.
var part_players: Dictionary[SongPart, AudioStreamPlayer] = {}

## The linear gain each part's audio is at or fading towards: 1 when playing, 0 when muted after a miss.
var _part_gains: Dictionary[SongPart, float] = {}
## The running fade for each part, if any.
var _part_fades: Dictionary[SongPart, Tween] = {}


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

## The [member song_position] compensated for audio latency, which is what the [member track] shows.
var track_position: float:
	get: return song_position - Songs.audio_latency_ms / 1000

## Begin playing the song that [param part] belongs to, with [param part] on the [member track] at [param difficulty].
func play(part: SongPart, difficulty: Difficulty.Level):
	var song := part.song
	track.load_song(part, difficulty)
	
	current_song = song
	current_stats = PerformanceStats.new(part)
	
	# Prepare audio
	for fade: Tween in _part_fades.values():
		fade.kill()
	_part_fades.clear()
	_part_gains.clear()
	for part_player: AudioStreamPlayer in part_players.values():
		part_player.queue_free()
	part_players.clear()
	
	player.stream = load(song.audio_path)
	for song_part: SongPart in song.parts:
		var part_player := AudioStreamPlayer.new()
		part_player.playback_type = player.playback_type
		part_player.stream = load(song_part.audio_path)
		part_player.finished.connect(_on_player_finished)
		add_child(part_player)
		part_players[song_part] = part_player
	
	# Start every stream within the same mix step, so they play sample-aligned.
	AudioServer.lock()
	player.play()
	for part_player: AudioStreamPlayer in part_players.values():
		part_player.play()
	AudioServer.unlock()


func _get_configuration_warnings() -> PackedStringArray:
	if track == null:
		return ["No PartTrack has been assigned."]
	return []


func _ready() -> void:
	if Engine.is_editor_hint(): return
	
	track.note_hit.connect(_on_part_track_note_hit)
	track.note_missed.connect(_on_part_track_note_missed)
	track.hold_finished.connect(_on_part_track_hold_finished)
	track.hold_released.connect(_on_part_track_hold_released)
	track.wrong_note.connect(_on_part_track_wrong_note)
	track.position_source = func(): return track_position


func _process(delta: float) -> void:
	if Engine.is_editor_hint(): return
	
	if player.playing:
		track.visible = true
		track.update(track_position)
	else:
		track.visible = false



## Fade the audio of [param part] to [param gain] (linear, 0 to 1) over [constant MUTE_FADE_S].
func _fade_part(part: SongPart, gain: float) -> void:
	if _part_gains.get(part, 1.0) == gain:
		return
	_part_gains[part] = gain
	if _part_fades.has(part):
		_part_fades[part].kill()
	var fade := create_tween()
	fade.tween_property(part_players[part], "volume_linear", gain, MUTE_FADE_S)
	_part_fades[part] = fade


func _on_part_track_note_hit(note: NoteData, offset_s: float) -> void:
	var judgement := current_stats.record_hit(note, offset_s)
	_fade_part(track.part, 0.0 if judgement == Scoring.Judgement.MISS else 1.0)


func _on_part_track_note_missed(note: NoteData) -> void:
	current_stats.record_miss(note)
	_fade_part(track.part, 0.0)


func _on_part_track_hold_finished(note: NoteData) -> void:
	current_stats.record_hold_finished(note)


func _on_part_track_hold_released(note: NoteData) -> void:
	_fade_part(track.part, 0.0)


func _on_part_track_wrong_note(beat: float, track: int) -> void:
	current_stats.record_wrong_note(beat, track)
	# A sound for pressing when no note is there would play here.


## Called when any of the song's audio players finishes; the song ends when all of them have.
func _on_player_finished() -> void:
	# Players that end in the same mix step each get here; only the first of them ends the song.
	if current_song == null:
		return
	if player.playing or part_players.values().any(func(p: AudioStreamPlayer): return p.playing):
		return
	song_finished.emit(current_song)
	current_song = null
	track.unload()
	# TODO: Save stats
