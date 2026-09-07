extends Node
## Lists every food item, its physics box, and what the model actually fits to.
## Run when a model looks wrong or after adding one:
##   Godot --headless --path . res://_inspect.tscn
func _ready() -> void:
	var main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	await get_tree().process_frame
	print("--- prepared visuals: %d of %d items ---" % [main._visuals.size(), main.ITEMS.size()])
	for item in main.ITEMS:
		if not main._visuals.has(item.name):
			print("  MISSING MODEL  %-14s (falls back to a plain coloured shape)" % item.name)
			continue
		var v = main._visuals[item.name]
		var box: AABB = v.transform * v.mesh.get_aabb()
		print("  %-14s box w=%.2f h=%.2f  |  model fits w=%.2f d=%.2f h=%.2f" % [
			item.name, item.width, item.height, box.size.x, box.size.z, box.size.y])
	get_tree().quit()
