class_name AreaExit extends Area3D
## A place at an area's edge that leads to an entrance of another area.
##
## The band travels when every player is inside it, so nobody is left behind. A glowing patch on
## the ground shows where it is, brighter the more of the band is standing in it. Where grass hides
## the patch from the camera, a fainter copy shows through, like a hidden player's silhouette.

## The scene of the area this exit leads to.
@export_file("*.tscn") var to_area: String
## The name of the entrance in that area where the band arrives.
@export var to_entrance: StringName
## The size of the exit, in units: across, up and in depth. It should reach the edge wall behind
## it, so a player who walks until the wall stops them is still inside it.
@export var size := Vector3(8, 2, 4)

## The glow's opacity with nobody in the exit, and with everyone in it.
const GLOW_EMPTY := 0.2
const GLOW_FULL := 0.7
## How much of the glow shows through whatever hides it.
const THROUGH_COVER := 0.5

## Draws only the parts of the glow that something else is in front of.
const _THROUGH_SHADER := """
shader_type spatial;
render_mode unshaded, depth_test_inverted, depth_draw_never, cull_disabled;
uniform vec4 color : source_color;
void fragment() {
	ALBEDO = color.rgb;
	ALPHA = color.a;
}
"""

var _glow: StandardMaterial3D
var _through: ShaderMaterial


func _ready() -> void:
	add_to_group("area_exits")
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	shape.position.y = size.y / 2
	add_child(shape)
	var patch := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(size.x, size.z)
	_glow = StandardMaterial3D.new()
	_glow.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_glow.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_glow.albedo_color = Color(1.0, 0.85, 0.4, GLOW_EMPTY)
	var shader := Shader.new()
	shader.code = _THROUGH_SHADER
	_through = ShaderMaterial.new()
	_through.shader = shader
	_glow.next_pass = _through
	_set_glow(GLOW_EMPTY)
	plane.material = _glow
	patch.mesh = plane
	patch.position.y = 0.03
	add_child(patch)


## Whether every one of [param characters] is inside this exit, and brighten the glow by how many are.
func holds(characters: Array[BandCharacter]) -> bool:
	var inside := characters.filter(func(c): return overlaps_body(c)).size()
	_set_glow(lerpf(GLOW_EMPTY, GLOW_FULL, float(inside) / maxi(characters.size(), 1)))
	return not characters.is_empty() and inside == characters.size()


func _set_glow(alpha: float) -> void:
	_glow.albedo_color.a = alpha
	_through.set_shader_parameter("color", Color(_glow.albedo_color, alpha * THROUGH_COVER))
