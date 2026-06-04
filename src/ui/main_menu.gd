extends Control

signal story_pressed()
signal freeplay_pressed()
signal settings_pressed()




func _on_story_button_pressed() -> void:
	story_pressed.emit()


func _on_freeplay_button_pressed() -> void:
	freeplay_pressed.emit()


func _on_settings_button_pressed() -> void:
	settings_pressed.emit()
