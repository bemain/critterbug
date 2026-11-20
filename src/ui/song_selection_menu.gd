extends Control
## Lets the players pick a song.

signal back_pressed()
signal song_selected(song: Song)

@onready var title_label: Label = $VBoxContainer/Label
@onready var item_list: ItemList = $VBoxContainer/ItemList

## Whether the event the list is handling is the second press of a double-click.
var _is_double_click := false


func _ready() -> void:
	visibility_changed.connect(_focus_list)
	_show_songs()


func _show_songs() -> void:
	title_label.text = "Select a song"
	item_list.clear()
	for song: Song in Songs.songs:
		item_list.add_item(song.title)
	_focus_list()


## Focus the list with its first item selected, so a gamepad or the keyboard can drive the menu.
func _focus_list() -> void:
	if not is_visible_in_tree() or item_list.item_count == 0:
		return
	item_list.select(0)
	item_list.grab_focus()


func _on_back_button_pressed() -> void:
	back_pressed.emit()


func _on_item_list_gui_input(event: InputEvent) -> void:
	_is_double_click = event is InputEventMouseButton and event.double_click


## A single left click chooses an item. The second press of a double-click is ignored, since the
## first one has already changed the list.
func _on_item_list_item_clicked(index: int, _at_position: Vector2, mouse_button_index: int) -> void:
	if mouse_button_index == MOUSE_BUTTON_LEFT and not _is_double_click:
		_choose(index)


## Confirming with the keyboard or a gamepad chooses the selected item. Moving through the list only
## selects, so it never starts a song.
func _on_item_list_item_activated(index: int) -> void:
	if not _is_double_click:
		_choose(index)


func _choose(index: int) -> void:
	song_selected.emit(Songs.songs[index])
