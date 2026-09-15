extends Node
## Builds a tower, then stops touching it and watches whether anything keeps
## moving. A settled stack should go quiet; jitter shows up as angular velocity
## that never decays, or a lean that keeps flipping sign.
func _ready() -> void:
	randomize()
	var all_ang := []
	var all_moving := []
	for round_i in 4:
		var r = await _one_tower()
		if r.is_empty(): continue
		all_ang.append(r.ang)
		all_moving.append(r.moving)
	var sa := 0.0
	for v in all_ang: sa += v
	var sm := 0.0
	for v in all_moving: sm += v
	if all_ang.size() > 0:
		print("AVERAGE over %d towers: worst angular %.3f, pieces still moving %.2f" % [
			all_ang.size(), sa / all_ang.size(), sm / all_moving.size()])
	get_tree().quit()


func _one_tower() -> Dictionary:
	var main = null
	for attempt in 8:
		main = load("res://scenes/main.tscn").instantiate()
		add_child(main)
		await get_tree().process_frame
		var guard := 0
		while main.pieces.get_child_count() < 6 and main.state != 2 and guard < 3000:
			await get_tree().process_frame
			guard += 1
			if main.state == 0 and absf(main.hook.position.x - _aim(main)) < 0.12:
				main._drop()
		if main.pieces.get_child_count() >= 6 and main.state != 2:
			break
		main.free(); main = null
	if main == null:
		return {}

	# wait until nothing is in the air, or we measure a falling piece, not jitter
	var settle_guard := 0
	while main.state != 0 and main.state != 2 and settle_guard < 600:
		await get_tree().process_frame
		settle_guard += 1
	if main.state == 2:
		main.free(); return {}
	
	var samples := 0
	var worst_ang := 0.0
	var worst_lin := 0.0
	var sign_flips := 0
	var last_sign := {}
	var still_moving := 0
	for i in 240:
		await get_tree().physics_frame
		if main.state == 2:
			print("  the tower fell over on its own during the watch")
			break
		samples += 1
		var moving_now := 0
		for p in main.pieces.get_children():
			var b: RigidBody3D = p
			if b.freeze: continue
			var a: float = b.angular_velocity.length()
			var l: float = b.linear_velocity.length()
			worst_ang = maxf(worst_ang, a)
			worst_lin = maxf(worst_lin, l)
			if a > 0.05 or l > 0.05: moving_now += 1
			var sg: int = signi(int(round(b.rotation.z * 1000.0)))
			if last_sign.has(b) and last_sign[b] != sg and sg != 0:
				sign_flips += 1
			last_sign[b] = sg
		still_moving = maxi(still_moving, moving_now)
	main.free()
	return {"ang": worst_ang, "moving": float(still_moving)}

func _aim(main) -> float:
	var best_top := -999.0
	var x := 0.0
	for p in main.pieces.get_children():
		var b: AABB = main._world_box(p)
		if b.position.y + b.size.y > best_top:
			best_top = b.position.y + b.size.y
			x = b.position.x + b.size.x * 0.5
	return x
