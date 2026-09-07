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
var sound_on := true
## Kept separate from sound: a muted phone in public should still buzz.
var haptics_on := true


func _ready() -> void:
	load_all()
	_apply_sound()


## Returns true if this run beat the record, so the game can say so.
func submit_score(score: int) -> bool:
	if score <= high_score:
		return false
	high_score = score
	save_all()
	return true


func set_sound(on: bool) -> void:
	sound_on = on
	_apply_sound()
	save_all()


func toggle_sound() -> void:
	set_sound(not sound_on)


func set_haptics(on: bool) -> void:
	haptics_on = on
	save_all()


## Mutes the master bus. There is no audio in the game yet, so today this changes
## nothing you can hear — but it is wired to the real thing, so the moment any
## sound is added the toggle already works.
func _apply_sound() -> void:
	var master := AudioServer.get_bus_index("Master")
	if master >= 0:
		AudioServer.set_bus_mute(master, not sound_on)


func load_all() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return
	high_score = int(cfg.get_value("score", "best", 0))
	sound_on = bool(cfg.get_value("settings", "sound", true))
	haptics_on = bool(cfg.get_value("settings", "haptics", true))


func save_all() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("score", "best", high_score)
	cfg.set_value("settings", "sound", sound_on)
	cfg.set_value("settings", "haptics", haptics_on)
	cfg.save(SAVE_PATH)
