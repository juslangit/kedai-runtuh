extends Node
## I cannot hear the game, so this checks what can be checked: every sound file
## loads, the music is set to loop, playback actually starts, and the mute toggle
## really reaches the master bus.
func _ready() -> void:
	var was_music := SaveData.music_on
	var was_sfx := SaveData.sfx_on
	var bad := 0
	print("--- sound files ---")
	for key in Audio.SFX:
		for path in Audio.SFX[key]:
			var ok := ResourceLoader.exists(path)
			var stream: AudioStream = load(path) if ok else null
			if stream == null:
				print("  MISSING  %-14s %s" % [key, path]); bad += 1
			else:
				print("  ok  %-9s %-42s %5.2fs" % [key, path.get_file(), stream.get_length()])

	print("--- music ---")
	var m: AudioStream = load(Audio.MUSIC_PATH)
	if m == null:
		print("  MISSING music"); bad += 1
	else:
		print("  ok  %s  %.1fs  %s" % [Audio.MUSIC_PATH.get_file(), m.get_length(), m.get_class()])

	print("--- playback ---")
	Audio.start_music()
	await get_tree().create_timer(0.3, true, false, true).timeout
	var mus: AudioStreamPlayer = Audio._music
	print("  music playing=%s  loop=%s  volume=%.1fdB" % [
		mus.playing, (mus.stream.loop if mus.stream is AudioStreamMP3 else "n/a"), mus.volume_db])

	for key in ["click", "land", "perfect", "creak", "crash", "release", "miss"]:
		Audio.play(key)
	await get_tree().create_timer(0.1, true, false, true).timeout
	var active := 0
	for p in Audio._players:
		if p.playing: active += 1
	print("  sfx players active after 7 plays: %d" % active)

	print("--- mute toggle ---")
	# Music and effects sit on their own buses, so each switch must mute its own
	# bus and leave the other one alone.
	var music_bus := AudioServer.get_bus_index("Music")
	var sfx_bus := AudioServer.get_bus_index("SFX")
	SaveData.set_music(false)
	print("  music off -> music muted=%s  sfx muted=%s" % [
		AudioServer.is_bus_mute(music_bus), AudioServer.is_bus_mute(sfx_bus)])
	SaveData.set_music(true)
	SaveData.set_sfx(false)
	print("  sfx off   -> music muted=%s  sfx muted=%s" % [
		AudioServer.is_bus_mute(music_bus), AudioServer.is_bus_mute(sfx_bus)])
	SaveData.set_sfx(true)
	print("  both on   -> music muted=%s  sfx muted=%s" % [
		AudioServer.is_bus_mute(music_bus), AudioServer.is_bus_mute(sfx_bus)])

	# These toggles write to the real save file, so put back whatever was set
	# before the check ran rather than leaving both switches on.
	SaveData.set_music(was_music)
	SaveData.set_sfx(was_sfx)
	print("  restored  -> music=%s sfx=%s" % [SaveData.music_on, SaveData.sfx_on])

	print("RESULT: %s" % ("all files present" if bad == 0 else "%d MISSING" % bad))
	get_tree().quit()
