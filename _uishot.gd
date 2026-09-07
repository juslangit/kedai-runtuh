extends Node
## Captures each screen so the UI can be checked without playing by hand.
const OUT := "/private/tmp/claude-501/-Users-juslangit/a1ac5792-094c-4962-80d1-46c4e82ee111/scratchpad/shots"

func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	randomize()

	# 1. main menu
	var menu = load("res://scenes/main_menu.tscn").instantiate()
	add_child(menu)
	for i in 20: await get_tree().process_frame
	await _shot("ui_menu")
	menu.free()

	# 2. the game, mid-run. Retry if a run ends early — the pause menu can only
	# be shown while a game is actually in progress.
	var main = null
	for attempt in 8:
		main = load("res://scenes/main.tscn").instantiate()
		add_child(main)
		await get_tree().process_frame
		var guard := 0
		while main.score < 5 and main.state != 2 and guard < 4000:
			await get_tree().process_frame
			guard += 1
			if main.state == 0 and absf(main.hook.position.x - _aim(main)) < 0.10:
				main._drop()
		if main.score >= 5 and main.state != 2:
			break
		main.free()
		main = null
	if main == null:
		print("could not reach a mid-run state"); get_tree().quit(); return
	for i in 10: await get_tree().process_frame
	await _shot("ui_hud")

	# 3. pause menu
	main._pause()
	for i in 6: await get_tree().process_frame
	await _shot("ui_pause")
	main._resume()

	# 4. game over
	main._game_over("TOPPLED!")
	for i in 200: await get_tree().process_frame
	await _shot("ui_gameover")

	print("high score now: ", SaveData.high_score)
	get_tree().quit()

func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("%s/%s.png" % [OUT, name])
	print("saved ", name)

func _aim(main) -> float:
	var best_top := -999.0
	var x := 0.0
	for p in main.pieces.get_children():
		var b: AABB = main._world_box(p)
		if b.position.y + b.size.y > best_top:
			best_top = b.position.y + b.size.y
			x = b.position.x + b.size.x * 0.5
	return x
