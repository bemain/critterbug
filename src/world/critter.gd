class_name Critter extends Node3D
## A critter the band can talk to. When a player stands within [member talk_radius], a prompt shows
## above it, and that player's confirm starts [member dialogue] at [member title].
##
## Its look and its collision are the one [code]Model[/code] child (for now the snail,
## [code]src/world/critters/Snail.tscn[/code]); swap that node to change the critter.

## The conversation, as a Dialogue Manager file.
@export var dialogue: DialogueResource
## Where in [member dialogue] the conversation starts.
@export var title := "start"
## How close a player must be to talk, in units, from the middle of the critter.
@export var talk_radius := 2.5

@onready var _prompt: Label3D = $Prompt


func _ready() -> void:
	add_to_group("critters")
	_prompt.visible = false


## Whether [param character] is close enough to talk.
func can_talk_to(character: BandCharacter) -> bool:
	var offset := character.global_position - global_position
	return Vector2(offset.x, offset.z).length() <= talk_radius


## Show the prompt if [param is_shown].
func show_prompt(is_shown: bool) -> void:
	_prompt.visible = is_shown
