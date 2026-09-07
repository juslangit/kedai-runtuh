extends Node
## All the game's sound in one place, registered as the autoload `Audio`.
##
## Everything is CC0 — see CREDITS.md. Nothing here needs attribution, and the
## sound toggle works by muting the master bus in SaveData, so this file never
## has to check whether sound is on.

const MUSIC_PATH := "res://assets/audio/music/ramen_lofi.mp3"
const MUSIC_VOLUME_DB := -16.0   ## music sits well under the game
const SFX_PLAYERS := 12          ## how many sounds can overlap; a collapse uses several

## Each entry is a list of takes on the same sound. One is picked at random and
## pitched slightly, so twenty landings in a row never sound like a loop.
const SFX := {
	"click":   ["res://assets/audio/sfx/ui_click.wav"],
	"release": ["res://assets/audio/sfx/release.wav"],
	"perfect": ["res://assets/audio/sfx/perfect.wav"],
	"miss":    ["res://assets/audio/sfx/miss.wav"],
	"land": [
		"res://assets/audio/sfx/land_0.ogg", "res://assets/audio/sfx/land_1.ogg",
		"res://assets/audio/sfx/land_2.ogg", "res://assets/audio/sfx/land_3.ogg",
		"res://assets/audio/sfx/land_4.ogg",
	],
	"creak": [
		"res://assets/audio/sfx/creak_0.ogg", "res://assets/audio/sfx/creak_1.ogg",
		"res://assets/audio/sfx/creak_2.ogg",
	],
	"crash": [
		"res://assets/audio/sfx/crash_glass_0.ogg", "res://assets/audio/sfx/crash_glass_1.ogg",
		"res://assets/audio/sfx/crash_glass_2.ogg", "res://assets/audio/sfx/crash_glass_3.ogg",
		"res://assets/audio/sfx/crash_glass_4.ogg", "res://assets/audio/sfx/crash_plate_0.ogg",
		"res://assets/audio/sfx/crash_plate_1.ogg", "res://assets/audio/sfx/crash_plate_2.ogg",
	],
}

var _loaded := {}
var _players: Array[AudioStreamPlayer] = []
var _next := 0
var _music: AudioStreamPlayer


func _ready() -> void:
	# Sound must keep working while the tree is paused, or the pause menu's own
	# buttons would be silent.
	process_mode = Node.PROCESS_MODE_ALWAYS
	_make_buses()

	for key in SFX:
		var takes: Array[AudioStream] = []
		for path in SFX[key]:
			var s: AudioStream = load(path)
			if s == null:
				push_warning("Missing sound: %s" % path)
				continue
			takes.append(s)
		_loaded[key] = takes

	for i in SFX_PLAYERS:
		var p := AudioStreamPlayer.new()
		p.process_mode = Node.PROCESS_MODE_ALWAYS
		p.bus = "SFX"
		add_child(p)
		_players.append(p)

	_music = AudioStreamPlayer.new()
	_music.process_mode = Node.PROCESS_MODE_ALWAYS
	_music.volume_db = MUSIC_VOLUME_DB
	_music.bus = "Music"
	add_child(_music)

	# The buses exist now, so the saved settings can finally be applied.
	SaveData.apply_audio()


## Two buses, so music and effects can be silenced independently.
func _make_buses() -> void:
	for bus_name in ["Music", "SFX"]:
		if AudioServer.get_bus_index(bus_name) >= 0:
			continue
		AudioServer.add_bus()
		var i := AudioServer.bus_count - 1
		AudioServer.set_bus_name(i, bus_name)
		AudioServer.set_bus_send(i, "Master")


## Play one sound. `pitch` shifts it; `spread` randomises the pitch a little on
## top, which is what stops repeated sounds becoming a machine gun.
func play(key: String, pitch := 1.0, spread := 0.06, volume_db := 0.0) -> void:
	var takes: Array = _loaded.get(key, [])
	if takes.is_empty():
		return
	var p := _players[_next]
	_next = (_next + 1) % _players.size()
	p.stream = takes[randi() % takes.size()]
	p.pitch_scale = maxf(0.05, pitch + randf_range(-spread, spread))
	p.volume_db = volume_db
	p.play()


## A pile of dishes going over is not one sound — it is several, close together.
func play_crash() -> void:
	play("crash", 0.9, 0.08, 2.0)
	for i in 4:
		await get_tree().create_timer(randf_range(0.04, 0.16), true, false, true).timeout
		if not is_inside_tree():
			return
		play("crash", randf_range(0.8, 1.25), 0.1, randf_range(-6.0, 1.0))


func start_music() -> void:
	if _music.playing:
		return
	var stream: AudioStream = load(MUSIC_PATH)
	if stream == null:
		push_warning("Missing music: %s" % MUSIC_PATH)
		return
	# Godot does not loop an imported mp3 unless told to.
	if stream is AudioStreamMP3:
		stream.loop = true
	_music.stream = stream
	_music.play()


func stop_music() -> void:
	_music.stop()


## Give every button in a screen a click, without wiring each one by hand.
func wire_buttons(root: Node) -> void:
	for node in _all_buttons(root):
		if not node.pressed.is_connected(_on_any_button):
			node.pressed.connect(_on_any_button)


func _on_any_button() -> void:
	play("click", 1.0, 0.03)


func _all_buttons(n: Node, acc: Array = []) -> Array:
	if n is BaseButton:
		acc.append(n)
	for c in n.get_children():
		_all_buttons(c, acc)
	return acc
