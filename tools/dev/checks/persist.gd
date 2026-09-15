extends Node
## Checks the thing that was actually asked for: the high score must survive a
## new game, and a new game must start from zero.
func _ready() -> void:
	print("start: high_score=%d" % SaveData.high_score)

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

	# Sound setting round trip.
	SaveData.set_sound(false)
	SaveData.sound_on = true
	SaveData.load_all()
	print("sound after reload: %s (expected false)" % SaveData.sound_on)
	SaveData.set_sound(true)
	get_tree().quit()
