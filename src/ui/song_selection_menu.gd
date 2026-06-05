extends Control

signal back_pressed()
signal song_selected(song: Song)

@onready var song_list = $VBoxContainer/ItemList

func _ready() -> void:
	song_list.clear()
	for song: Song in Songs.songs:
		song_list.add_item(song.title)


func _on_back_button_pressed() -> void:
	back_pressed.emit()


func _on_item_list_item_selected(index: int) -> void:
	song_selected.emit(Songs.songs[index])
