extends Node
const OUT := "/Users/juslangit/Desktop/project/game/kedai-runtuh/press"
func _ready() -> void:
	SaveData.high_score = 23
	var menu = load("res://scenes/main_menu.tscn").instantiate()
	add_child(menu)
	for i in 20: await get_tree().process_frame
	await _shot("01_main_menu")

	var panel = menu.get_node("UI/SettingsPanel")
	panel.open()
	for i in 6: await get_tree().process_frame
	await _shot("05_settings")

	panel.get_node("Center/Panel/Box/Credits").pressed.emit()
	for i in 6: await get_tree().process_frame
	await _shot("06_credits")
	get_tree().quit()

func _shot(n: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("%s/%s.png" % [OUT, n])
	print("saved ", n)
