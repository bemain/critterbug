extends Control

signal story_pressed()
signal freeplay_pressed()
signal settings_pressed()


func _ready() -> void:
	visibility_changed.connect(_focus_first)
	_focus_first()


## Focus the first button, so a gamepad or the keyboard can drive the menu.
func _focus_first() -> void:
	if is_visible_in_tree():
		$VBoxContainer/FreeplayButton.grab_focus()


func _on_story_button_pressed() -> void:
	story_pressed.emit()


func _on_freeplay_button_pressed() -> void:
	freeplay_pressed.emit()


func _on_settings_button_pressed() -> void:
	settings_pressed.emit()
