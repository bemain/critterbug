class_name CHRPDataResource extends ResourceFormatLoader
## Loads .chrp song files as [Song] resources.


func _get_recognized_extensions() -> PackedStringArray:
	return ["chrp"]


func _handles_type(type: StringName) -> bool:
	return type == "CHRPDataResource" or type == "Resource"


func _get_resource_type(path: String) -> String:
	if path.to_lower().ends_with(".chrp"):
		return "CHRPDataResource"
	return ""


## Parses the .chrp file at [param path] into a [Song], or returns null if it can't be opened.
func _load(path: String, original_path: String, use_sub_threads: bool, cache_mode: int) -> Song:
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	var dir_path = path.get_base_dir() + "/"

	if file == null:
		var error_code: Error = FileAccess.get_open_error()
		printerr("Failed to open CHRP file '%s': %s" % [path, error_string(error_code)])
		return null

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
						["_", var audio]: song.audio_path = dir_path + audio
						[var instr, var audio]: audio_paths[instr] = dir_path +  audio
	
	# Parts
	var part: SongPart = null
	var beat := 0
	for line in lines.slice(line_n): # Continue after the header
		if line.begins_with("#"): continue # Comment
		
		if line.begins_with("["):
			# New part
			if part != null:
				song.parts.append(part)
			beat = 0
			part = SongPart.new(song, line.substr(1, line.length() - 2))
			if audio_paths.has(part.name):
				part.audio_path = audio_paths[part.name]
			continue
		
		# Part data
		for track: int in range(ceil(line.length() / 4.0)):
			var notes: String = line.substr(track*4, 4).strip_edges()
			for offset: int in range(notes.length()):
				var subbeat := float(offset) / notes.length()
				match notes[offset]:
					"-":
						# Sustain the previous note
						var notes_on_track = part.notes.filter(func(n): return n.track == track)
						assert(notes_on_track.size() >= 1, "Sustain has to be preceeded by a note")
						var note = notes_on_track[-1]
						var subbeat_end = subbeat + 1.0 / notes.length()
						note.duration = beat - note.beat + subbeat_end - note.subbeat
					
					var digit when digit.is_valid_int():
						# Add note
						var priority := int(digit)
						var note := NoteData.new(track, beat, subbeat, priority)
						part.notes.append(note)
				
					# TODO: Handle strange notes
				
		beat += 1
	
	if part != null:
		song.parts.append(part)
	
	
	file.close()
	
	return song
