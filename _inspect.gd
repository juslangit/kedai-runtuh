extends Node
func _ready() -> void:
	var main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	await get_tree().process_frame
	print("--- prepared visuals: %d of %d items ---" % [main._visuals.size(), main.ITEMS.size()])
	for item in main.ITEMS:
		if not main._visuals.has(item.name):
			print("  MISSING MODEL  %-14s (falls back to a grey shape)" % item.name)
			continue
		var v = main._visuals[item.name]
		var box: AABB = v.transform * v.mesh.get_aabb()
		print("  %-14s target w=%.2f h=%.2f  |  model fits to w=%.2f d=%.2f h=%.2f  centre=(%.3f,%.3f,%.3f)" % [
			item.name, item.width, item.height,
			box.size.x, box.size.z, box.size.y,
			box.get_center().x, box.get_center().y, box.get_center().z])
	get_tree().quit()
