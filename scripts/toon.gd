class_name Toon
extends RefCounted
## Makes 3D models match the painted background: flat two-tone shading and a
## dark outline, instead of the soft realistic shading Godot does by default.
##
## The food models keep their own colours and textures. Only HOW light falls on
## them changes, which is why one function can restyle every item at once.
##
## To make the look stronger or softer, change the three numbers below.

## How wide the soft edge between the lit side and the shadow side is.
## 0 = a razor-sharp cartoon line, 1 = almost normal shading.
const SHADE_SOFTNESS := 0.25
const OUTLINE_COLOR := Color(0.16, 0.11, 0.08)
const OUTLINE_THICKNESS := 0.028

static var _outline: ShaderMaterial
## Each source material is converted once and then shared, so a tower of thirty
## plates is still one material, not thirty.
static var _converted := {}


## The cel-shaded version of a material, with the outline attached.
static func material(source: Material) -> Material:
	if source != null and _converted.has(source):
		return _converted[source]

	var mat: BaseMaterial3D
	if source is BaseMaterial3D:
		mat = source.duplicate()
	else:
		mat = StandardMaterial3D.new()
	mat.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
	mat.specular_mode = BaseMaterial3D.SPECULAR_TOON
	mat.roughness = SHADE_SOFTNESS
	mat.metallic = 0.0
	# a small, faint highlight — a big shiny spot reads as plastic, not paint
	mat.metallic_specular = 0.2
	mat.next_pass = outline()

	if source != null:
		_converted[source] = mat
	return mat


## Restyle every surface of a mesh in place.
static func apply(target: MeshInstance3D) -> void:
	if target.mesh == null:
		return
	for i in target.mesh.get_surface_count():
		target.set_surface_override_material(i, material(target.mesh.surface_get_material(i)))


static func outline() -> ShaderMaterial:
	if _outline == null:
		_outline = ShaderMaterial.new()
		_outline.shader = load("res://shaders/outline.gdshader")
		_outline.set_shader_parameter("outline_color", OUTLINE_COLOR)
		_outline.set_shader_parameter("thickness", OUTLINE_THICKNESS)
	return _outline
