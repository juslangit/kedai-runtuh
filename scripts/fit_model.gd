extends Node3D
## Scales and positions a decorative model so it lines up with the game.
##
## Same idea as the food: the game's measurements are fixed and the model is made
## to match them, so one model can be swapped for another without anything else
## changing. Nothing here touches physics — the table's collision box is a
## separate node and is left alone.

@export var target_width := 5.0    ## how wide the model should end up, in metres
@export var target_height := 3.0   ## how tall the model should end up, in metres
@export var target_top_y := 0.0    ## world height its top surface should sit at
@export var centre_x := true       ## centre it left-to-right on the play area


func _ready() -> void:
	var box := _combined_aabb()
	if box.size.y <= 0.0:
		push_warning("fit_model: nothing to measure under %s" % name)
		return

	# Width and height are set independently. Width has to match the collision
	# box exactly — a table that looks wider than it collides has ends that look
	# solid and are not. Height has to reach the floor. One uniform scale cannot
	# do both, so the model gets stretched, and since only the top of the table is
	# ever on screen that costs nothing.
	var sx: float = target_width / box.size.x
	var sy: float = target_height / box.size.y
	scale = Vector3(sx, sy, sx)

	# The top surface is what the food lands on, so that edge has to be exact.
	position.y = target_top_y - (box.position.y + box.size.y) * sy
	if centre_x:
		position.x = -box.get_center().x * sx


## The space every mesh below this node occupies, in this node's own coordinates.
func _combined_aabb() -> AABB:
	var out := AABB()
	var first := true
	var to_local := global_transform.affine_inverse()
	for mi in _meshes(self):
		var local: AABB = (to_local * mi.global_transform) * mi.get_aabb()
		if first:
			out = local
			first = false
		else:
			out = out.merge(local)
	return out


func _meshes(n: Node, acc: Array = []) -> Array:
	if n is MeshInstance3D:
		acc.append(n)
	for c in n.get_children():
		_meshes(c, acc)
	return acc
