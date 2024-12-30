extends Node

# Load a .chrp file into memory
func load_song(path: String) -> Song:
	var file = FileAccess.open(path, FileAccess.READ)
	var content = file.get_as_text()
	var song: Song = Song.new()
	
	var audio_paths: Dictionary = {}
	
	var lines := content.split("\n")
	# Header data
	var line_n := -1
	while line_n < lines.size() - 1 and not lines[line_n + 1].begins_with("["):
		line_n += 1
		var line: String = lines[line_n]
		if line.is_empty(): continue # Empty line
		
		match Array(line.split(":")).map(func (s): return s.strip_edges()):
			["title", var title]: song.title = title as String
			["artist", var artist]: song.artist = artist as String
			["bpm", var bpm]: song.bpm = int(bpm)
			["bpb", var bpb]: song.bpb = int(bpb)
			["audio", ..]:
				while lines[line_n+1].begins_with("    "):
					line_n += 1
					match Array(lines[line_n].split(":")).map(func (s): return s.strip_edges()):
						["_", var audio]: song.audio_path = audio
						[var instr, var audio]: audio_paths[instr] = audio
	
	# Instruments
	var instrument: Instrument
	var beat := 0
	for line in lines.slice(line_n): # Continue after the header
		if line.begins_with("#"): continue # Comment
		
		if line.begins_with("["):
			# New instrument
			if instrument != null:
				song.instruments.append(instrument)
			beat = 0
			instrument = Instrument.new(line.substr(1, line.length() - 2))
			if audio_paths.has(instrument.name):
				instrument.audio_path = audio_paths[instrument.name]
			continue
		
		# Instrument data
		for j in range(ceil(line.length() / 4.0)):
			var notes = line.substr(j*4, 4).strip_edges()
			for offset in range(notes.length()):
				# . or other strange note. TODO: Handle strange notes
				if not notes[offset].is_valid_int(): continue
				# Add note
				var note := Note.new(j, beat, float(offset) / notes.length(), int(notes[offset]))
				instrument.notes.append(note)
		beat += 1
	
	if instrument != null:
		song.instruments.append(instrument)
	
	return song
