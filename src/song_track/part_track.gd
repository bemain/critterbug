class_name PartTrack extends Node2D
## A track that displays the notes of a [member part] as they come towards the hit marker.
##
## It only draws: which notes appear, and whether they are hit, missed or held, is decided by a
## [Judge], which tells the track through [method add_note] and the [code]show_*[/code] methods.


## The part that is playing on this track.
var part: SongPart

var song: Song:
	get: return part.song

## The length of the entire track, in pixels.
var length: float = 500:
	get: return path.curve.get_baked_length()

## The length of the part of the track above the hit marker, i.e. the part where notes are "active".
var active_length: float:
	get: return length * hit_marker_position

## The width of the track, in pixels.
##
## Note that this is measured along the track, meaning that the bounding box for the track might be 
## much wider, since the track is not necessarily straight.
var width: float:
	get: return $Visuals.width

## The scene of a [NoteNode]. PartTrack.tscn sets it, so it is loaded with the track and stays
## loaded. A script can't preload it: the scene uses note.gd, which refers to this script.
@export var note_scene: PackedScene

## The number of beats shown on the track, above the hit marker.
@export var beats: int = 4
## The number of pixels each note moves per beat.
var beat_length: float:
	get: return active_length / beats
## The duration of each beat, in seconds.
var beat_duration: float:
	get: return 60.0/song.bpm

## Where the label under the track goes, and how wide it is, in pixels.
const LABEL_POSITION := Vector2(-80, 490)
const LABEL_WIDTH := 200.0

## The most recent position in the song reported.
var last_position: float = -INF

## The player whose notes this track shows, if any.
var player: Player

## The player's number, from 1, shown with their part, score and combo.
var player_number: int

## Shows who plays this track, with their score and combo.
var _label: Label

## The node showing each note on the track.
var _nodes: Dictionary[NoteData, NoteNode] = {}

@onready var path: Path2D = $Path2D

## How much of the track is above the hit marker, as a fraction
var hit_marker_position: float:
	get: return $Visuals.hit_marker_position


func _ready() -> void:
	# Create beat lines
	for i in range(beats):
		var line := Line2D.new()
		line.width = 1.0
		$Beats.add_child(line)
	
	_label = Label.new()
	_label.position = LABEL_POSITION
	_label.size = Vector2(LABEL_WIDTH, 0)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_label)


func _process(_delta: float) -> void:
	if player == null or player.stats == null:
		_label.text = ""
		return
	var stats := player.stats
	_label.text = "P%d  %s\nScore: %d\nCombo: %d  x%d" % [player_number, part.name.capitalize(), stats.score, stats.combo, Scoring.multiplier(stats.combo)]


## Reset the track to show [param part].
func load_song(part: SongPart):
	last_position = -INF
	self.part = part
	for node: NoteNode in $Notes.get_children():
		node.queue_free()
	_nodes.clear()


## Show that [param player], number [param number], plays this track.
func show_player(player: Player, number: int) -> void:
	self.player = player
	player_number = number


## Show [param note], which has just come into play.
func add_note(note: NoteData) -> void:
	var node: NoteNode = NoteNode.instantiate(note, self)
	_nodes[note] = node
	node.tree_exiting.connect(func(): if _nodes.get(note) == node: _nodes.erase(note))
	$Notes.add_child(node)


## Show that [param note] was hit, and is being held if it is a sustained note.
func show_hit(note: NoteData) -> void:
	_nodes[note].show_hit()


## Show that [param note] was missed.
func show_miss(note: NoteData) -> void:
	_nodes[note].show_miss()


## Show that the sustained [param note] was held to its end.
func show_hold_finished(note: NoteData) -> void:
	_nodes[note].show_hold_finished()


## Show that the sustained [param note] was let go of before its end.
func show_hold_released(note: NoteData) -> void:
	_nodes[note].show_hold_released()


## Move the notes along the track.
## Should be called every frame with [param song_position] as the current position in the [member song]. 
func update(song_position: float) -> void:
	if song_position <= last_position: return  # Can't go backwards
	
	last_position = song_position
	
	# Update beat lines
	for i: int in range(beats):
		var line: Line2D = $Beats.get_child(i)
		var t = fposmod((song_position / beat_duration + i) / beats, 1)
		var path_point = path.curve.sample_baked_with_rotation(hit_marker_position * t * path.curve.get_baked_length())
		line.set_points(PackedVector2Array([
			path_point.get_origin() + width * 2 * path_point.y,
			path_point.get_origin() - width * 2 * path_point.y,
		]))
	
	# Update notes
	for note: NoteNode in $Notes.get_children():
		note.update(song_position)

