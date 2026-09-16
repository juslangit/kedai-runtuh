extends Node
## Renders portfolio-quality stills at full portrait resolution.
var OUT := ProjectSettings.globalize_path("res://press")
func _ready() -> void:
	SaveData.high_score = 23
	# 1. main menu
	var menu = load("res://scenes/main_menu.tscn").instantiate()
	add_child(menu)
	for i in 30: await get_tree().process_frame
	await _shot("01_main_menu")
	menu.get_node("UI/SettingsPanel").open()
	for i in 8: await get_tree().process_frame
	await _shot("05_settings")
	menu.free()

	# 2. gameplay, at a few tower heights
	var main = null
	for attempt in 6:
		main = load("res://scenes/main.tscn").instantiate()
		add_child(main)
		await get_tree().process_frame
		var taken := {}
		var guard := 0
		while main.state != 2 and guard < 2500:
			await get_tree().process_frame
			guard += 1
			if main.state != 0: continue
			var n: int = main.score
			if n in [3, 6, 9] and not taken.has(n) and main.preview.visible:
				taken[n] = true
				await _shot("0%d_tower_%d" % [taken.size() + 1, n])
			if absf(main.hook.position.x - _aim(main)) < 0.10:
				main._drop()
		if taken.size() >= 2: break
		main.free(); main = null
	print("done")
	get_tree().quit()

func _shot(n: String) -> void:
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	var err := img.save_png("%s/%s.png" % [OUT, n])
	print("saved %s  (%dx%d)  err=%d" % [n, img.get_width(), img.get_height(), err])

func _aim(main) -> float:
	var t := -999.0; var x := 0.0
	for p in main.pieces.get_children():
		var b: AABB = main._world_box(p)
		if b.position.y + b.size.y > t: t = b.position.y + b.size.y; x = b.position.x + b.size.x * 0.5
	return x
