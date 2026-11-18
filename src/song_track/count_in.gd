class_name CountIn
## The count-in played before a song: one bar of clicks on the beat, with the first beat accented.
##
## The clicks are a placeholder generated in code. To use a recorded sound instead, return it from
## [method make_clicks]. Whatever it returns must last exactly one bar of the song.

const MIX_RATE := 44100
## How long each click rings, in seconds.
const CLICK_S := 0.03
const CLICK_HZ := 1000.0
const ACCENT_HZ := 1500.0
## Peak level of a click, as a fraction of full scale.
const CLICK_LEVEL := 0.5


## One bar of clicks for [param song], on each of its beats.
static func make_clicks(song: Song) -> AudioStreamWAV:
	var data := _empty_bar(song)
	var beat_frames := 60.0 / song.bpm * MIX_RATE
	var decay_s := CLICK_S / 5
	for beat in song.bpb:
		var start := roundi(beat * beat_frames)
		var hz := ACCENT_HZ if beat == 0 else CLICK_HZ
		for i in roundi(CLICK_S * MIX_RATE):
			var t := float(i) / MIX_RATE
			var level := sin(TAU * hz * t) * exp(-t / decay_s) * CLICK_LEVEL
			data.encode_s16((start + i) * 2, roundi(level * 32767))
	return _wav(data)


## One bar of silence for [param song], to hold back the other streams during the count-in.
static func make_silence(song: Song) -> AudioStreamWAV:
	return _wav(_empty_bar(song))


static func _empty_bar(song: Song) -> PackedByteArray:
	var data := PackedByteArray()
	data.resize(roundi(song.bpb * 60.0 / song.bpm * MIX_RATE) * 2)
	return data


static func _wav(data: PackedByteArray) -> AudioStreamWAV:
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = MIX_RATE
	wav.data = data
	return wav
