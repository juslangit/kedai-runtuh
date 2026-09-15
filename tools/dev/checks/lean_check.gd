extends Node
## Measures the thing that was actually wrong: pieces coming to rest on their
## edge. Reports how far each settled piece is leaning, plus score and how often
## the same item comes round again.
func _ready() -> void:
	randomize()
	var scores := []
	var tipped := 0        # pieces resting past 60 degrees - the "on its rim" look
	var total_pieces := 0
	var repeats := 0
	var landings := 0
	for run in 5:
		var main = load("res://scenes/main.tscn").instantiate()
		add_child(main)
		await get_tree().process_frame
		var seen: Array[String] = []
		var last_score := 0
		var guard := 0
		while main.state != 2 and guard < 3000:
			await get_tree().process_frame
			guard += 1
			if main.score != last_score:
				landings += 1
				var nm := String(main.next_item.get("name", ""))
				if nm in seen.slice(maxi(0, seen.size() - 3)):
					repeats += 1
				seen.append(nm)
				last_score = main.score
			if main.state == 0 and absf(main.hook.position.x - _aim(main)) < 0.12:
				main._drop()
		# measure every settled piece
		for p in main.pieces.get_children():
			total_pieces += 1
			if absf(rad_to_deg((p as RigidBody3D).rotation.z)) > 60.0:
				tipped += 1
		scores.append(main.score)
		main.free()
	var pct := 0.0 if total_pieces == 0 else 100.0 * float(tipped) / float(total_pieces)
	print("scores: %s" % str(scores))
	print("pieces on their edge (>60 deg): %d of %d  (%.0f%%)" % [tipped, total_pieces, pct])
	print("same item within 3 drops: %d of %d landings" % [repeats, landings])
	get_tree().quit()

func _aim(main) -> float:
	var best_top := -999.0
	var x := 0.0
	for p in main.pieces.get_children():
		var b: AABB = main._world_box(p)
		if b.position.y + b.size.y > best_top:
			best_top = b.position.y + b.size.y
			x = b.position.x + b.size.x * 0.5
	return x
