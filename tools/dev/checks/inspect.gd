extends Node
## Lists every food item, its physics box, and what its model actually fits to.
func _ready() -> void:
	var main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	await get_tree().process_frame
	print("--- prepared visuals: %d of %d items ---" % [main._visuals.size(), main.ITEMS.size()])
	var missing := 0
	for item in main.ITEMS:
		if not main._visuals.has(item.name):
			print("  MISSING MODEL  %-15s node=%s" % [item.name, item.node]); missing += 1
			continue
		var v = main._visuals[item.name]
		var box: AABB = v.transform * v.mesh.get_aabb()
		print("  tier%d  %-15s box %.2f x %.2f  |  model %.2f x %.2f" % [
			item.tier, item.name, item.width, item.height, box.size.x, box.size.y])
	print("MISSING: %d" % missing)
	get_tree().quit()
