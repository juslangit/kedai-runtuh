extends Node
## Builds a tower, then saves a few frames as PNGs so the art can be checked.
const OUT := "/private/tmp/claude-501/-Users-juslangit/a1ac5792-094c-4962-80d1-46c4e82ee111/scratchpad/shots"
func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	seed(7)
	var main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	await get_tree().process_frame
	var shot := 0
	for i in 400:
		await get_tree().process_frame
		# capture while a piece is hanging and waiting, which is what the player
		# actually looks at most of the time
		if main.state == 0 and main.score in [2, 4, 6] and shot < 3 and main.preview.visible:
			shot += 1
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png("%s/hang_%d.png" % [OUT, main.score])
			print("saved hanging shot at score ", main.score)
		if main.state == 0 and absf(main.hook.position.x - _aim(main)) < 0.10:
			main._drop()
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(OUT + "/final.png")
	print("done, score=", main.score)
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
