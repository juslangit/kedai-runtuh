extends Node
func _ready() -> void:
	for uid in ["06c880f5035344418f9a112926ee610c","548fc7c6d0dd4b2f90de83494b52ea40","ab96499ddb3b4bd7bc739e4f99dad409"]:
		var ps: PackedScene = load("res://assets/models/_tabletest/%s/scene.gltf" % uid)
		if ps == null:
			print(uid, "  FAILED TO LOAD"); continue
		var root := ps.instantiate()
		add_child(root)
		var total := AABB(); var first := true; var n := 0
		for mi in _meshes(root):
			var a: AABB = mi.global_transform * mi.get_aabb()
			if first: total = a; first = false
			else: total = total.merge(a)
			n += 1
		print("%s  meshes=%d  size=(%.3f, %.3f, %.3f)  top_y=%.3f  w/h=%.2f  w/d=%.2f" % [
			uid.substr(0,8), n, total.size.x, total.size.y, total.size.z,
			total.position.y + total.size.y,
			total.size.x / maxf(total.size.y, 0.001),
			total.size.x / maxf(total.size.z, 0.001)])
		root.queue_free()
	get_tree().quit()

func _meshes(n: Node, acc: Array = []) -> Array:
	if n is MeshInstance3D: acc.append(n)
	for c in n.get_children(): _meshes(c, acc)
	return acc
