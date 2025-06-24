class_name InstrumentTrack
extends Node2D

# The scene that uses this script. Used for the [instantiate] method.
const _scene: PackedScene = preload("res://src/song_track/instrument_track.tscn")

# Create an instance of this scene, with the given parameters.
static func instantiate(song: Song, instrument: Instrument) -> InstrumentTrack:
	var track: InstrumentTrack = _scene.instantiate()
	track.song = song
	track.instrument = instrument
	
	if not instrument.audio_path.is_empty():
		track.get_node("AudioStreamPlayer").stream = load(instrument.audio_path)
	return track


var song: Song
var instrument: Instrument

# The number of seconds this tracks would need to wait between beginning note creation and starting 
# audio playback for the audio and the visuals to be in sync.
var initial_delay: float:
	get: return beats * beat_duration
	

# The length of the track, in pixels
@export var length: int = 500
# The number of beats shown on the track
@export var beats: int = 4

var beat_length: float:
	get: return float(length) / beats
var beat_duration: float:
	get: return 60.0/song.bpm

var current_beat: int = 0

@onready var path: Path2D = $Path2D


## Begin playing audio and creating notes for the given [instrument]. 
## 
## [actual_initial_delay] is the actual number of seconds we have to wait between beginning note 
## creation and starting audio playback, so that all the tracks are in sync with the audio.
## This is the maximum of [initial_delay] among all the instrument tracks for this song.
func start(initial_delay: float) -> void:
	# Wait for the first note to hit the bottom, so that the audio is in sync with the visuals	
	get_tree().create_timer(initial_delay, false).timeout.connect(func(): 
		# Start audio
		$AudioStreamPlayer.play()
	)
	
	# Give the other tracks enough time to sync audio and visuals.
	await get_tree().create_timer(initial_delay - self.initial_delay, false).timeout
	
	# Begin creating notes
	var beat_timer = Timer.new()
	beat_timer.wait_time = beat_duration
	beat_timer.one_shot = false
	beat_timer.connect("timeout", new_beat)
	add_child(beat_timer)
	beat_timer.start()


func new_beat() -> void:
	for n in instrument.notes_in_beat(current_beat):
		var note = NoteNode.instantiate(path, beats*beat_duration, n.track, $Visuals.width, current_beat * beat_duration, -beat_duration * n.subbeat)
		$Notes.add_child(note)
	
	current_beat += 1
