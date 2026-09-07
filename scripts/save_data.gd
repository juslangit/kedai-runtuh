extends Node
## Everything that has to outlive a single run: the high score and the sound
## setting. Registered as an autoload called SaveData, so every scene sees the
## same copy and nothing has to be passed between them.
##
## The high score lives HERE and not in the game scene. That is the whole point —
## starting a new game builds a fresh scene with a fresh score of zero, and the
## high score is untouched by that, because it was never part of the game scene
## to begin with. It is written to disk the moment it changes.

const SAVE_PATH := "user://kedai_runtuh.cfg"

var high_score := 0
## Music and effects are separate, because wanting a game quiet on the bus is not
## the same as wanting it silent.
var music_on := true
var sfx_on := true
## Separate again: a muted phone should still buzz in your hand.
var haptics_on := true


func _ready() -> void:
	load_all()


## Returns true if this run beat the record, so the game can say so.
func submit_score(score: int) -> bool:
	if score <= high_score:
		return false
	high_score = score
	save_all()
	return true


func set_music(on: bool) -> void:
	music_on = on
	apply_audio()
	save_all()


func set_sfx(on: bool) -> void:
	sfx_on = on
	apply_audio()
	save_all()


func set_haptics(on: bool) -> void:
	haptics_on = on
	save_all()


func reset_high_score() -> void:
	high_score = 0
	save_all()


## Mutes the two audio buses. Called by Audio once it has created them, and again
## whenever a setting changes.
func apply_audio() -> void:
	_mute("Music", not music_on)
	_mute("SFX", not sfx_on)


func _mute(bus_name: String, muted: bool) -> void:
	var i := AudioServer.get_bus_index(bus_name)
	if i >= 0:
		AudioServer.set_bus_mute(i, muted)


func load_all() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return
	high_score = int(cfg.get_value("score", "best", 0))
	# "sound" was a single switch before music and effects were split apart.
	# An older save still carries it, so it seeds both.
	var legacy: bool = bool(cfg.get_value("settings", "sound", true))
	music_on = bool(cfg.get_value("settings", "music", legacy))
	sfx_on = bool(cfg.get_value("settings", "sfx", legacy))
	haptics_on = bool(cfg.get_value("settings", "haptics", true))


func save_all() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("score", "best", high_score)
	cfg.set_value("settings", "music", music_on)
	cfg.set_value("settings", "sfx", sfx_on)
	cfg.set_value("settings", "haptics", haptics_on)
	cfg.save(SAVE_PATH)
