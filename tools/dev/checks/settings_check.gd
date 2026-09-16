extends Node
## Checks each setting actually reaches the thing it claims to control, and that
## it survives being written to disk and read back.
func _ready() -> void:
	var menu = load("res://scenes/main_menu.tscn").instantiate()
	add_child(menu)
	await get_tree().process_frame
	var panel = menu.get_node("UI/SettingsPanel")
	var box := "Center/Panel/Box/"

	print("--- panel opens from the main menu ---")
	menu.get_node("UI/Root/Layout/Settings").pressed.emit()
	await get_tree().process_frame
	print("  visible: %s" % panel.visible)
	print("  music='%s'  sfx='%s'  haptics='%s'" % [
		panel.get_node(box + "Music").text, panel.get_node(box + "Sfx").text,
		panel.get_node(box + "Haptics").text])

	print("--- each toggle reaches its audio bus ---")
	for pair in [["Music", "Music"], ["Sfx", "SFX"]]:
		panel.get_node(box + pair[0]).pressed.emit()
		await get_tree().process_frame
		var idx := AudioServer.get_bus_index(pair[1])
		print("  %-5s off -> bus '%s' muted = %s" % [pair[0], pair[1], AudioServer.is_bus_mute(idx)])
		panel.get_node(box + pair[0]).pressed.emit()
		await get_tree().process_frame
		print("  %-5s on  -> bus '%s' muted = %s" % [pair[0], pair[1], AudioServer.is_bus_mute(idx)])

	print("--- vibration toggle ---")
	panel.get_node(box + "Haptics").pressed.emit()
	print("  haptics_on = %s, button says '%s'" % [SaveData.haptics_on, panel.get_node(box + "Haptics").text])
	panel.get_node(box + "Haptics").pressed.emit()

	print("--- settings survive a reload from disk ---")
	SaveData.set_music(false); SaveData.set_sfx(true); SaveData.set_haptics(false)
	SaveData.music_on = true; SaveData.sfx_on = false; SaveData.haptics_on = true
	SaveData.load_all()
	print("  after reload: music=%s (want false)  sfx=%s (want true)  haptics=%s (want false)" % [
		SaveData.music_on, SaveData.sfx_on, SaveData.haptics_on])
	SaveData.set_music(true); SaveData.set_haptics(true)

	print("--- erase best score needs two taps ---")
	SaveData.high_score = 42
	var reset := panel.get_node(box + "Reset") as Button
	panel.open(); await get_tree().process_frame
	print("  shows: '%s'" % reset.text)
	reset.pressed.emit(); await get_tree().process_frame
	print("  one tap  -> high_score=%d, button='%s'" % [SaveData.high_score, reset.text])
	reset.pressed.emit(); await get_tree().process_frame
	print("  two taps -> high_score=%d" % SaveData.high_score)

	print("--- credits are present (CC-BY requires them in the game) ---")
	var body := panel.get_node("CreditsView/Center/Panel/Box/Body") as RichTextLabel
	# The kitchen and table models were replaced by the painted mamak stall on
	# 2026-09-15, so their authors no longer need crediting. Lilita One is OFL.
	var required := ["Pollypipe", "HoliznaCC0", "Kenney", "Lilita One"]
	var missing := 0
	for who in required:
		if who not in body.text:
			print("  MISSING credit: %s" % who)
			missing += 1
	print("  all required credits present: %s" % (missing == 0))
	get_tree().quit()
