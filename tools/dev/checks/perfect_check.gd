extends Node
## How often is a drop PERFECT? Run at two aiming accuracies: a machine that
## waits for the exact moment, and a sloppier one closer to a human tapping by eye.
func _ready() -> void:
	for tol in [0.20, 0.30, 0.40]:
		var perfects := 0
		var landings := 0
		var runs := 0
		for attempt in 4:
			var main = load("res://scenes/main.tscn").instantiate()
			add_child(main)
			await get_tree().process_frame
			var last := 0
			var guard := 0
			while main.state != 2 and guard < 2500:
				await get_tree().process_frame
				guard += 1
				if main.score != last:
					landings += 1
					if main.score - last >= 2:
						perfects += 1
					last = main.score
				if main.state == 0 and absf(main.hook.position.x - _aim(main)) < tol:
					main._drop()
			runs += 1
			main.free()
		var pct := 0.0 if landings == 0 else 100.0 * float(perfects) / float(landings)
		print("aim tolerance %.2f -> %d landings, %d perfect (%.0f%%)" % [tol, landings, perfects, pct])
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
