extends Node
## Simulates a competent player: aims at the horizontal centre of whatever is
## actually on top of the tower, and drops when the hook lines up.
func _ready() -> void:
	randomize()
	var main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	await get_tree().process_frame
	var ticks := 0
	while ticks < 3000:
		await get_tree().process_frame
		ticks += 1
		if main.state == 2:
			print("score=%d height=%.2f msg=%s" % [main.score, main.highest_y,
				main.reason_label.text])
			get_tree().quit(); return
		if main.state == 0 and absf(main.hook.position.x - _aim(main)) < 0.10:
			main._drop()
	print("score=%d height=%.2f msg=SURVIVED" % [main.score, main.highest_y])
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
