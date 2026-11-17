class_name CountIn
## The count-in played before a song: one bar of clicks on the beat, with the first beat accented.
## The latency calibration in the settings uses the same clicks.
##
## The clicks are a placeholder generated in code. To use a recorded sound instead, return it from
## [method make_click_track]. Whatever it returns must last exactly [param beats] beats.

const MIX_RATE := 44100
## How long each click rings, in seconds.
const CLICK_S := 0.03
const CLICK_HZ := 1000.0
const ACCENT_HZ := 1500.0
## Peak level of a click, as a fraction of full scale.
const CLICK_LEVEL := 0.5


## One bar of clicks for [param song], on each of its beats.
static func make_clicks(song: Song) -> AudioStreamWAV:
	return make_click_track(song.bpm, song.bpb)


## [param beats] clicks at [param bpm], one on each beat, with the first one accented.
static func make_click_track(bpm: float, beats: int) -> AudioStreamWAV:
	var data := _silent_beats(bpm, beats)
	var beat_frames := 60.0 / bpm * MIX_RATE
	var decay_s := CLICK_S / 5
	for beat in beats:
		var start := roundi(beat * beat_frames)
		var hz := ACCENT_HZ if beat == 0 else CLICK_HZ
		for i in roundi(CLICK_S * MIX_RATE):
			var t := float(i) / MIX_RATE
			var level := sin(TAU * hz * t) * exp(-t / decay_s) * CLICK_LEVEL
			data.encode_s16((start + i) * 2, roundi(level * 32767))
	return _wav(data)


## One bar of silence for [param song], to hold back the other streams during the count-in.
static func make_silence(song: Song) -> AudioStreamWAV:
	return _wav(_silent_beats(song.bpm, song.bpb))


static func _silent_beats(bpm: float, beats: int) -> PackedByteArray:
	var data := PackedByteArray()
	data.resize(roundi(beats * 60.0 / bpm * MIX_RATE) * 2)
	return data


static func _wav(data: PackedByteArray) -> AudioStreamWAV:
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = MIX_RATE
	wav.data = data
	return wav
