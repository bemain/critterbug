extends Node

# Load a .chrp file into memory
func load_song(path: String) -> Song:
	var file = FileAccess.open(path, FileAccess.READ)
	var content = file.get_as_text()
	var song: Song = Song.new()
	
	# Header
	for line: String in content.split("\n"):
		line = line.strip_edges()
		# Comment or empty line
		if line.begins_with("#") or line.is_empty(): continue
		# Header section is over
		if line.begins_with("["): break
		
		var key = line.split(":")[0].strip_edges()
		var value = line.split(":")[1].strip_edges()
		match key:
			"title": song.title = value
			"artist": song.artist = value
			"bpm": song.bpm = value
			"bpb": song.bpb = value
	
	# Instruments
	var r = RegEx.new()
	r.compile(r"\[(?<name>.*?)\][\r\n](?<data>(.*([\r\n]|$))*?(?=\[|$))")
	for m in r.search_all(content):
		var instrument = Instrument.new()
		instrument.name = m.get_string("name")
		var beat := 0
		for line in m.get_string("data").split("\n"):
			# Comment or empty line
			if line.begins_with("#") or line.is_empty(): continue
			
			beat += 1
			for i in range(ceil(line.length() / 4.0)):
				var notes = line.substr(i*4, 4).strip_edges()
				for offset in range(notes.length()):
					# . or other strange note. TODO: Handle strange notes
					if not notes[offset].is_valid_int(): continue
					# Add note
					instrument.notes.append(Note.new(i, beat, float(offset) / notes.length(), int(notes[offset])))
		
		song.instruments.append(instrument)
	
	return song
