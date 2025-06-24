# This script defines a custom resource loader for .chrp files.
extends ResourceFormatLoader
class_name CHRPDataResource


# Returns an array of strings, where each string is an extension this loader can handle.
# Godot uses this to determine which loader to use for a given file.
func _get_recognized_extensions() -> PackedStringArray:
	# This loader will recognize files with the ".chrp" extension.
	return ["chrp"]


# Returns true if this loader can load resources of the specified 'type'.
# This helps Godot understand if your loader is relevant for a given resource request.
func _handles_type(type: StringName) -> bool:
	# This loader is designed to load our custom CHRPDataResource type.
	# We also handle "Resource" as a fallback or general type, as custom resources
	# often inherit from Resource.
	return type == "CHRPDataResource" or type == "Resource"


# Returns the name of the resource type that this loader produces for a given path.
# This is called before _load and can help Godot determine the expected type.
func _get_resource_type(path: String) -> String:
	# If the path ends with ".chrp", we'll return our custom resource type name.
	if path.to_lower().ends_with(".chrp"):
		return "CHRPDataResource"
	return "" # Return empty string if not applicable

# This is the core method where you implement the actual loading logic for your .chrp file.
# It takes the 'path' to the file and an optional 'original_path' (usually the same).
# It should return the loaded Resource object or null if loading fails.
func _load(path: String, original_path: String, use_sub_threads: bool, cache_mode: int) -> Song:
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	var dir_path = path.get_base_dir() + "/"

	# Error handling: Check if the file could be opened.
	if file == null:
		# Use FileAccess.get_open_error() to get a descriptive error message.
		var error_code: Error = FileAccess.get_open_error()
		printerr("Failed to open CHRP file '%s': %s" % [path, error_string(error_code)])
		return null # Return null to indicate loading failure.

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
	
	# Instruments
	var instrument: Instrument = null
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
	
	
	file.close()
	
	return song

# Helper function to convert an Error code to a human-readable string.
func error_string(error: Error) -> String:
	match error:
		OK: return "OK"
		ERR_UNAVAILABLE: return "Unavailable"
		ERR_UNCONFIGURED: return "Unconfigured"
		ERR_CANT_CREATE: return "Cannot Create"
		ERR_CANT_OPEN: return "Cannot Open"
		ERR_FILE_CANT_WRITE: return "Cannot Write"
		ERR_FILE_CANT_READ: return "Cannot Read"
		ERR_PARSE_ERROR: return "Parse Error"
		ERR_OUT_OF_MEMORY: return "Out of Memory"
		# Add more error codes as needed for better debugging
		_: return "Unknown Error (%s)" % str(error)
