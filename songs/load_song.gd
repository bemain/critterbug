extends Node


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.




func save_to_file(content):
	var file = FileAccess.open("user://save_game.dat", FileAccess.WRITE)
	file.store_string(content)
	

func load_from_file():
	var file = FileAccess.open("user://save_game.dat", FileAccess.READ)
	var content = file.get_as_text()
	return content
