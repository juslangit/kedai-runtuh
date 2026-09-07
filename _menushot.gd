extends Node
const OUT := "/private/tmp/claude-501/-Users-juslangit/a1ac5792-094c-4962-80d1-46c4e82ee111/scratchpad/shots"
func _ready() -> void:
	add_child(load("res://scenes/main_menu.tscn").instantiate())
	for i in 20: await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(OUT + "/ui_menu.png")
	print("saved menu")
	get_tree().quit()
