extends Control
## Lets the player pick a song, then the part of it they want to play.

signal back_pressed()
signal part_selected(part: SongPart)

@onready var title_label: Label = $VBoxContainer/Label
@onready var item_list: ItemList = $VBoxContainer/ItemList

## The song whose parts are listed, or null while the songs are listed.
var selected_song: Song


func _ready() -> void:
	_show_songs()


func _show_songs() -> void:
	selected_song = null
	title_label.text = "Select a song"
	item_list.clear()
	for song: Song in Songs.songs:
		item_list.add_item(song.title)


func _show_parts(song: Song) -> void:
	selected_song = song
	title_label.text = "Select a part"
	item_list.clear()
	for part: SongPart in song.parts:
		item_list.add_item(part.name)


func _on_back_button_pressed() -> void:
	if selected_song == null:
		back_pressed.emit()
	else:
		_show_songs()


func _on_item_list_item_selected(index: int) -> void:
	if selected_song == null:
		_show_parts(Songs.songs[index])
		return

	var part := selected_song.parts[index]
	_show_songs()
	part_selected.emit(part)
