@tool
class_name SongManager extends Node2D
## A node responsible for playing a song.
##
## It plays a song for a band of [Player]s: it shows each player's notes on their own [PartTrack],
## routes each player's presses to their [Judge], makes sure the audio is in sync with the visuals,
## and fades a part's audio while its players miss.
## TODO: This script should also handle syncing between players when implementing multiplayer

## Emitted when a [param song] has finished playing.
signal song_finished(song: Song)

## How long a part's audio takes to fade out after a miss, or back in after a hit, in seconds.
const MUTE_FADE_S := 0.05

const _PART_TRACK: PackedScene = preload("res://src/song_track/PartTrack.tscn")

## How wide a track is drawn at full size, including its hit marker, in pixels.
const TRACK_WIDTH := 340.0
## Where a track's origin sits: across, relative to its middle at full size; down, from the top of
## the layout. Its top starts above the screen, so notes come in from off screen.
const TRACK_ORIGIN := Vector2(-28, -27)

## The tracks of the current song, one per player, in the order of [member players].
var tracks: Array[PartTrack] = []

## Audio player for the [member current_song]'s backing track. The song's time follows it.
@onready var backing_player: AudioStreamPlayer = $AudioStreamPlayer

## One audio player per part of the [member current_song], so each part can be faded on its own.
## An audio player's volume is ramped per sample within each mix step, which keeps the fades free of clicks.
var part_players: Dictionary[SongPart, AudioStreamPlayer] = {}

## The linear gain each part's audio is at or fading towards: 1 when playing, 0 when muted because
## all of its players are missing.
var _part_gains: Dictionary[SongPart, float] = {}
## The running fade for each part, if any.
var _part_fades: Dictionary[SongPart, Tween] = {}


## The song currently played, if any
var current_song: Song

## The players of the current or last song.
var players: Array[Player] = []

## Whether each player's last note was missed, or let go of before its end.
var _is_missing: Dictionary[Player, bool] = {}

## How the [member players] did together in the current or last song.
var band: BandStats

## The statistics of the first player's current playthough of the [member current_song].
var current_stats: PerformanceStats:
	get: return players[0].stats if not players.is_empty() else null

## Reports when the players' lanes go down and up.
var lane_input: LaneInput

## Whether a song is currently being played
var playing: bool:
	get: return current_song != null

## The current position in the [member current_song], in seconds. It is negative during the count-in.
## It never decreases within a song, although the audio clock it follows can briefly read backwards.
var song_position: float:
	get:
		var audio_position := backing_player.get_playback_position() + AudioServer.get_time_since_last_mix() - _count_in_s
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

## The [member song_position] compensated for audio latency, which is what the [member tracks] show.
var track_position: float:
	get: return song_position - Songs.audio_latency_ms / 1000

## Begin playing the song that the [param players]' parts belong to.
func play(players: Array[Player]):
	var song := players[0].part.song
	current_song = song
	self.players = players
	_is_missing.clear()
	_remove_tracks()
	for i in players.size():
		var p := players[i]
		var track: PartTrack = _PART_TRACK.instantiate()
		add_child(track)
		_place(track, i, players.size())
		track.load_song(p.part)
		if p.number == 0:
			p.number = i + 1
		track.show_player(p, p.number)
		tracks.append(track)
		p.start(track.beats * track.beat_duration)
		p.judge.note_entered.connect(track.add_note)
		p.judge.note_hit.connect(func(note, judgement):
			track.show_hit(note)
			_on_player_judged(p, judgement == Scoring.Judgement.MISS))
		p.judge.note_missed.connect(func(note):
			track.show_miss(note)
			_on_player_judged(p, true))
		p.judge.hold_finished.connect(track.show_hold_finished)
		p.judge.hold_released.connect(func(note):
			track.show_hold_released(note)
			_on_player_judged(p, true))
		p.judge.wrong_note.connect(_on_judge_wrong_note)
	var player_stats: Array[PerformanceStats] = []
	player_stats.assign(players.map(func(p: Player): return p.stats))
	band = BandStats.new(player_stats)
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
	backing_player.stream = _after_count_in(clicks, load(song.audio_path))
	for song_part: SongPart in song.parts:
		var part_player := AudioStreamPlayer.new()
		part_player.playback_type = backing_player.playback_type
		part_player.stream = _after_count_in(silence, load(song_part.audio_path))
		part_player.finished.connect(_on_player_finished)
		add_child(part_player)
		part_players[song_part] = part_player
	
	# Start every stream within the same mix step, so they play sample-aligned.
	AudioServer.lock()
	backing_player.play()
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


## Place [param track] as track [param index] of [param count], side by side across the layout, and
## shrink it if they wouldn't fit at full size.
func _place(track: PartTrack, index: int, count: int) -> void:
	var slot_width: float = ProjectSettings.get_setting("display/window/size/viewport_width") / float(count)
	var scale := minf(1.0, slot_width / TRACK_WIDTH)
	track.scale = Vector2(scale, scale)
	track.position = Vector2(slot_width * (index + 0.5) + TRACK_ORIGIN.x * scale, TRACK_ORIGIN.y)


func _remove_tracks() -> void:
	for track: PartTrack in tracks:
		track.queue_free()
	tracks.clear()


func _ready() -> void:
	if Engine.is_editor_hint(): return
	
	lane_input = LaneInput.new()
	add_child(lane_input)
	# Presses are timed with the live position rather than the one from the last frame.
	lane_input.lane_pressed.connect(func(device, lane):
		for p: Player in _players_of(device): p.judge.press(lane, track_position))
	lane_input.lane_released.connect(func(device, lane):
		for p: Player in _players_of(device): p.judge.release(lane, track_position))


func _process(delta: float) -> void:
	if Engine.is_editor_hint(): return
	
	if backing_player.playing:
		var position := track_position
		for i in players.size():
			players[i].judge.advance(position)
			tracks[i].update(position)



## A note of [param player]'s was judged: hit, or missed if [param is_missing], which also counts
## letting go of a hold early. Count it for the band, and mute the player's part while all of its
## players are missing.
func _on_player_judged(player: Player, is_missing: bool) -> void:
	if is_missing:
		band.record_miss()
	else:
		band.record_hit()
	_is_missing[player] = is_missing
	var is_part_missing := players.all(func(p: Player): return p.part != player.part or _is_missing.get(p, false))
	_fade_part(player.part, 0.0 if is_part_missing else 1.0)


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


## The players of the current song that play with [param device].
func _players_of(device: int) -> Array[Player]:
	if not playing:
		return []
	return players.filter(func(p: Player): return p.accepts(device))


func _on_judge_wrong_note(_lane: int, _time_s: float) -> void:
	# A sound for pressing when no note is there would play here.
	pass


## Called when any of the song's audio players finishes; the song ends when all of them have.
func _on_player_finished() -> void:
	# Players that end in the same mix step each get here; only the first of them ends the song.
	if current_song == null:
		return
	if backing_player.playing or part_players.values().any(func(p: AudioStreamPlayer): return p.playing):
		return
	song_finished.emit(current_song)
	current_song = null
	_remove_tracks()
	# TODO: Save stats
