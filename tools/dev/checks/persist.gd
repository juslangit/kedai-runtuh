extends Node
## Checks the thing that was actually asked for: the high score must survive a
## new game, and a new game must start from zero.
func _ready() -> void:
	print("start: high_score=%d" % SaveData.high_score)

	# This check writes to the same save file the real game uses, so everything it
	# finds is put back at the end. Without this it quietly replaced a genuine high
	# score with the fake 17 below.
	var was_high := SaveData.high_score
	var was_music := SaveData.music_on
	var was_sfx := SaveData.sfx_on
	var was_haptics := SaveData.haptics_on

	# Pretend a great run happened.
	SaveData.high_score = 0
	SaveData.save_all()
	var beat_it := SaveData.submit_score(17)
	print("submit 17 -> record=%s high_score=%d" % [beat_it, SaveData.high_score])

	# A worse run must not touch it.
	var beat_again := SaveData.submit_score(5)
	print("submit  5 -> record=%s high_score=%d" % [beat_again, SaveData.high_score])

	# Reload from disk, as a fresh launch of the game would.
	SaveData.high_score = -1
	SaveData.load_all()
	print("after reload from disk: high_score=%d" % SaveData.high_score)

	# Now start an actual game scene and check what it reads.
	var main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	await get_tree().process_frame
	print("new game scene: score=%d best=%d hud_best='%s'" % [
		main.score, main.best, main.hud_best_label.text])

	# Sound settings round trip. Music and effects are two separate switches,
	# so both have to survive a reload on their own.
	SaveData.set_music(false)
	SaveData.set_sfx(true)
	SaveData.music_on = true
	SaveData.sfx_on = false
	SaveData.load_all()
	print("after reload: music=%s (expected false)  sfx=%s (expected true)" % [
		SaveData.music_on, SaveData.sfx_on])

	# Haptics too, since it is saved in the same file.
	SaveData.set_haptics(false)
	SaveData.haptics_on = true
	SaveData.load_all()
	print("after reload: haptics=%s (expected false)" % SaveData.haptics_on)

	# Put the real save back exactly as it was.
	SaveData.high_score = was_high
	SaveData.music_on = was_music
	SaveData.sfx_on = was_sfx
	SaveData.haptics_on = was_haptics
	SaveData.apply_audio()
	SaveData.save_all()
	SaveData.load_all()
	print("restored: high_score=%d music=%s sfx=%s haptics=%s" % [
		SaveData.high_score, SaveData.music_on, SaveData.sfx_on, SaveData.haptics_on])
	get_tree().quit()
