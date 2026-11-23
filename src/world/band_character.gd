class_name BandCharacter extends CharacterBody3D
## A band member walking in the world: a placeholder shape in their player's colour, moved by
## their player's device. The band are bug-sized critters in a world of giant grass, so a
## character is about 1 unit tall.
##
## Where grass or a rock hides a character from the camera, a see-through silhouette in their
## colour is drawn over whatever is in front, so every player can find themselves.

## The colour of each player number, P1 to P4.
const COLORS: Array[Color] = [Color("e74c3c"), Color("3498db"), Color("2ecc71"), Color("f1c40f")]

## How fast a character walks, in units per second.
const SPEED := 2.5

const HEIGHT := 1.0
const RADIUS := 0.25

## How opaque the silhouette of a hidden character is.
const SILHOUETTE_ALPHA := 0.45

## Draws only the parts of a character that something else is in front of.
const _SILHOUETTE_SHADER := """
shader_type spatial;
render_mode unshaded, depth_test_inverted, depth_draw_never, cull_back;
uniform vec4 color : source_color;
void fragment() {
	ALBEDO = color.rgb;
	ALPHA = color.a;
}
"""

## The player this character belongs to.
var player: Player

## Where this character wants to go this physics frame, on the ground plane, before the band holds
## it back.
var wanted_velocity := Vector3.ZERO


func _init(player: Player) -> void:
	self.player = player
	name = "P%d" % player.number
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.height = HEIGHT
	capsule.radius = RADIUS
	shape.shape = capsule
	shape.position.y = HEIGHT / 2
	add_child(shape)
	var mesh := MeshInstance3D.new()
	var capsule_mesh := CapsuleMesh.new()
	capsule_mesh.height = HEIGHT
	capsule_mesh.radius = RADIUS
	var color := COLORS[(player.number - 1) % COLORS.size()]
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	var shader := Shader.new()
	shader.code = _SILHOUETTE_SHADER
	var silhouette := ShaderMaterial.new()
	silhouette.shader = shader
	silhouette.set_shader_parameter("color", Color(color, SILHOUETTE_ALPHA))
	silhouette.render_priority = 1
	material.next_pass = silhouette
	capsule_mesh.material = material
	mesh.mesh = capsule_mesh
	mesh.position.y = HEIGHT / 2
	add_child(mesh)


## Read the player's device into [member wanted_velocity].
func read_input() -> void:
	var push := Vector2.ZERO
	for device: int in player.devices:
		push += MoveInput.vector(device)
	push = push.limit_length(1.0)
	wanted_velocity = Vector3(push.x, 0, push.y) * SPEED


## Walk with [param ground_velocity], falling with gravity, and slide along whatever is in the way.
func walk(ground_velocity: Vector3, delta: float) -> void:
	velocity.x = ground_velocity.x
	velocity.z = ground_velocity.z
	if is_on_floor():
		velocity.y = 0.0
	else:
		velocity.y -= ProjectSettings.get_setting("physics/3d/default_gravity") * delta
	move_and_slide()
