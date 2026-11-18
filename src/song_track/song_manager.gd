@tool
class_name SongManager extends Node2D
## A node responsible for playing a song.
##
## It owns the [Judge] that judges the player's presses, makes sure the audio is in sync with the
## visuals, and fades a part's audio when its player misses.
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

## Judges the player's presses during the [member current_song].
var judge: Judge

## Reports when the player's lanes go down and up.
var lane_input: LaneInput

## Whether a song is currently being played
var playing: bool:
	get: return current_song != null

## The current position in the [member current_song], in seconds. It is negative during the count-in.
## It never decreases within a song, although the audio clock it follows can briefly read backwards.
var song_position: float:
	get:
		var audio_position := player.get_playback_position() + AudioServer.get_time_since_last_mix() - _count_in_s
		_max_song_position = maxf(_max_song_position, audio_position)
		return _max_song_position

## The highest [member song_position] handed out during the current song.
var _max_song_position: float = -INF

## How long the [member current_song]'s count-in lasts, in seconds.
var _count_in_s: float = 0.0

## The beat of the count-in that the player is hearing, from 1 to the song's beats per bar, or 0
## outside the count-in.
var count_in_beat: int:
	get:
		if not playing or track_position >= 0 or track_position < -_count_in_s:
			return 0
		return int((track_position + _count_in_s) / (60.0 / current_song.bpm)) + 1

## The [member song_position] compensated for audio latency, which is what the [member track] shows.
var track_position: float:
	get: return song_position - Songs.audio_latency_ms / 1000

## Begin playing the song that [param part] belongs to, with [param part] on the [member track] at
## [param difficulty]. If [param is_adaptive], the difficulty then adapts to how the player does.
func play(part: SongPart, difficulty: Difficulty.Level, is_adaptive := false):
	var song := part.song
	track.load_song(part)
	
	current_song = song
	current_stats = PerformanceStats.new(part, difficulty, is_adaptive)
	judge = Judge.new(current_stats, track.beats * track.beat_duration)
	judge.note_entered.connect(track.add_note)
	judge.note_hit.connect(_on_judge_note_hit)
	judge.note_missed.connect(_on_judge_note_missed)
	judge.hold_finished.connect(track.show_hold_finished)
	judge.hold_released.connect(_on_judge_hold_released)
	judge.wrong_note.connect(_on_judge_wrong_note)
	_max_song_position = -INF
	
	# Prepare audio
	for fade: Tween in _part_fades.values():
		fade.kill()
	_part_fades.clear()
	_part_gains.clear()
	for part_player: AudioStreamPlayer in part_players.values():
		part_player.queue_free()
	part_players.clear()
	
	# Every stream starts with one bar: the count-in clicks on the backing track, silence on the parts.
	# They play as one playlist each, so the song itself starts on the same sample in all of them.
	var clicks := CountIn.make_clicks(song)
	var silence := CountIn.make_silence(song)
	_count_in_s = clicks.get_length()
	player.stream = _after_count_in(clicks, load(song.audio_path))
	for song_part: SongPart in song.parts:
		var part_player := AudioStreamPlayer.new()
		part_player.playback_type = player.playback_type
		part_player.stream = _after_count_in(silence, load(song_part.audio_path))
		part_player.finished.connect(_on_player_finished)
		add_child(part_player)
		part_players[song_part] = part_player
	
	# Start every stream within the same mix step, so they play sample-aligned.
	AudioServer.lock()
	player.play()
	for part_player: AudioStreamPlayer in part_players.values():
		part_player.play()
	AudioServer.unlock()


## [param stream] preceded by [param count_in], with no crossfade between them.
func _after_count_in(count_in: AudioStream, stream: AudioStream) -> AudioStreamPlaylist:
	var playlist := AudioStreamPlaylist.new()
	playlist.loop = false
	playlist.fade_time = 0.0
	playlist.stream_count = 2
	playlist.set_list_stream(0, count_in)
	playlist.set_list_stream(1, stream)
	return playlist


func _get_configuration_warnings() -> PackedStringArray:
	if track == null:
		return ["No PartTrack has been assigned."]
	return []


func _ready() -> void:
	if Engine.is_editor_hint(): return
	
	lane_input = LaneInput.new()
	add_child(lane_input)
	# Presses are timed with the live position rather than the one from the last frame.
	lane_input.lane_pressed.connect(func(lane): if judge != null: judge.press(lane, track_position))
	lane_input.lane_released.connect(func(lane): if judge != null: judge.release(lane, track_position))


func _process(delta: float) -> void:
	if Engine.is_editor_hint(): return
	
	if player.playing:
		var position := track_position
		judge.advance(position)
		track.visible = true
		track.update(position)
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


func _on_judge_note_hit(note: NoteData, judgement: Scoring.Judgement) -> void:
	track.show_hit(note)
	_fade_part(current_stats.part, 0.0 if judgement == Scoring.Judgement.MISS else 1.0)


func _on_judge_note_missed(note: NoteData) -> void:
	track.show_miss(note)
	_fade_part(current_stats.part, 0.0)


func _on_judge_hold_released(note: NoteData) -> void:
	track.show_hold_released(note)
	_fade_part(current_stats.part, 0.0)


func _on_judge_wrong_note(_lane: int, _time_s: float) -> void:
	# A sound for pressing when no note is there would play here.
	pass


## Called when any of the song's audio players finishes; the song ends when all of them have.
func _on_player_finished() -> void:
	# Players that end in the same mix step each get here; only the first of them ends the song.
	if current_song == null:
		return
	if player.playing or part_players.values().any(func(p: AudioStreamPlayer): return p.playing):
		return
	song_finished.emit(current_song)
	current_song = null
	judge = null
	# TODO: Save stats
