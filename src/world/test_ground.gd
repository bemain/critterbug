extends Node3D
## A plain test ground with one obstacle, for walking the band around until the real world scene
## exists. Run on its own, it spawns one keyboard player and one per connected gamepad.

## Where the obstacle box stands, and its size, in metres.
const OBSTACLE_POSITION := Vector3(0, 1, -6)
const OBSTACLE_SIZE := Vector3(4, 2, 1)
const GROUND_SIZE := Vector3(80, 1, 80)

var band: Band


func _ready() -> void:
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55, 30, 0)
	sun.shadow_enabled = true
	add_child(sun)
	var environment := WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.background_mode = Environment.BG_COLOR
	environment.environment.background_color = Color("87a8c4")
	environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color = Color(0.6, 0.6, 0.6)
	add_child(environment)
	add_child(_box("Ground", Vector3(0, -GROUND_SIZE.y / 2, 0), GROUND_SIZE, Color("6b8e4e")))
	add_child(_box("Obstacle", OBSTACLE_POSITION, OBSTACLE_SIZE, Color("8d7b68")))
	band = Band.new()
	add_child(band)
	if get_tree().current_scene == self:
		var players: Array[Player] = [Player.new([LaneInput.KEYBOARD], null, Difficulty.Level.NORMAL)]
		for pad in Input.get_connected_joypads():
			if players.size() < 4:
				players.append(Player.new([pad], null, Difficulty.Level.NORMAL))
		for i in players.size():
			players[i].number = i + 1
		band.spawn(players)


func _box(box_name: String, at: Vector3, size: Vector3, color: Color) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = box_name
	body.position = at
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	body.add_child(shape)
	var mesh := MeshInstance3D.new()
	var box_mesh := BoxMesh.new()
	box_mesh.size = size
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	box_mesh.material = material
	mesh.mesh = box_mesh
	body.add_child(mesh)
	return body
