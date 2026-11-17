extends Control
## Lets the player pick a song, then the part of it they want to play.

signal back_pressed()
signal part_selected(part: SongPart, difficulty: Difficulty.Level)

@onready var title_label: Label = $VBoxContainer/Label
@onready var item_list: ItemList = $VBoxContainer/ItemList
@onready var difficulty_row: Control = $VBoxContainer/Difficulty
@onready var difficulty_button: OptionButton = $VBoxContainer/Difficulty/DifficultyButton

## The song whose parts are listed, or null while the songs are listed.
var selected_song: Song


func _ready() -> void:
	for level_name: String in Difficulty.Level.keys():
		difficulty_button.add_item(level_name.capitalize(), Difficulty.Level[level_name])
	difficulty_button.select(difficulty_button.get_item_index(Difficulty.Level.NORMAL))
	visibility_changed.connect(_focus_list)
	_show_songs()


func _show_songs() -> void:
	selected_song = null
	title_label.text = "Select a song"
	difficulty_row.hide()
	item_list.clear()
	for song: Song in Songs.songs:
		item_list.add_item(song.title)
	_focus_list()


func _show_parts(song: Song) -> void:
	selected_song = song
	title_label.text = "Select a part"
	difficulty_row.show()
	item_list.clear()
	for part: SongPart in song.parts:
		item_list.add_item(part.name)
	_focus_list()


## Focus the list with its first item selected, so a gamepad or the keyboard can drive the menu.
func _focus_list() -> void:
	if not is_visible_in_tree() or item_list.item_count == 0:
		return
	item_list.select(0)
	item_list.grab_focus()


func _on_back_button_pressed() -> void:
	if selected_song == null:
		back_pressed.emit()
	else:
		_show_songs()


## Called when an item is chosen: confirmed with the keyboard or a gamepad, or double-clicked.
## Moving through the list only selects, so it never starts a song.
func _on_item_list_item_activated(index: int) -> void:
	if selected_song == null:
		_show_parts(Songs.songs[index])
		return

	var part := selected_song.parts[index]
	_show_songs()
	part_selected.emit(part, difficulty_button.get_selected_id() as Difficulty.Level)
