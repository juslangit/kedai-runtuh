extends Node
## A sleeping tower must still be knocked about by the next landing, or putting
## pieces to sleep would have quietly turned the game into a stack of statues.
func _ready() -> void:
	randomize()
	var main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	await get_tree().process_frame
	var guard := 0
	while main.pieces.get_child_count() < 4 and main.state != 2 and guard < 2000:
		await get_tree().process_frame; guard += 1
		if main.state == 0 and absf(main.hook.position.x - _aim(main)) < 0.12:
			main._drop()
	while main.state != 0 and main.state != 2 and guard < 3000:
		await get_tree().process_frame; guard += 1
	if main.state == 2: print("ended early"); get_tree().quit(); return

	var asleep := 0
	for p in main.pieces.get_children():
		if (p as RigidBody3D).sleeping: asleep += 1
	print("before next drop: %d of %d pieces asleep" % [asleep, main.pieces.get_child_count()])

	# drop one deliberately off-centre so it lands hard on the stack
	main._drop()
	for i in 40: await get_tree().physics_frame
	var awake := 0
	var moved := 0.0
	for p in main.pieces.get_children():
		var b: RigidBody3D = p
		if not b.sleeping and not b.freeze: awake += 1
		moved = maxf(moved, b.linear_velocity.length())
	print("after a piece landed on it: %d pieces awake, fastest %.3f" % [awake, moved])
	print("VERDICT: %s" % ("the tower still reacts" if awake > 0 or moved > 0.01 else "PROBLEM - tower is inert"))
	get_tree().quit()

func _aim(main) -> float:
	var t := -999.0; var x := 0.0
	for p in main.pieces.get_children():
		var b: AABB = main._world_box(p)
		if b.position.y + b.size.y > t: t = b.position.y + b.size.y; x = b.position.x + b.size.x * 0.5
	return x
