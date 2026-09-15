extends Node
## Plays the game and saves a screenshot the first time it reaches each of a few
## scores, so the art can be checked at different tower heights.
var OUT := ProjectSettings.globalize_path("res://press")
const AT := [3, 6, 9]
func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	randomize()
	var main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	await get_tree().process_frame
	var taken := {}
	for i in 4000:
		await get_tree().process_frame
		if main.state == 2:
			break
		if main.state != 0:
			continue
		if main.score in AT and not taken.has(main.score) and main.preview.visible:
			taken[main.score] = true
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png("%s/0%d_tower_%d.png" % [OUT, taken.size() + 1, main.score])
			print("shot at score ", main.score)
		if absf(main.hook.position.x - _aim(main)) < 0.10:
			main._drop()
	# and one of the collapse
	await get_tree().create_timer(0.7).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(OUT + "/07_collapse.png")
	print("final score ", main.score)
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
