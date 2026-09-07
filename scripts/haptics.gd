class_name Haptics
extends RefCounted
## Short vibrations, in one place so the whole game's feel can be tuned together.
##
## `Input.vibrate_handheld` does nothing on desktop, so these are safe to call
## from anywhere. Haptics are separate from the SOUND toggle on purpose: people
## mute a game in public and still want to feel it.

const TAP_MS := 15       ## releasing a piece
const LAND_MS := 25      ## it settles on the tower
const PERFECT_MS := 40   ## dead centre
const COLLAPSE_MS := 250 ## the tower goes over


static func tap() -> void:
	_buzz(TAP_MS)


static func land() -> void:
	_buzz(LAND_MS)


static func perfect() -> void:
	_buzz(PERFECT_MS)


static func collapse() -> void:
	_buzz(COLLAPSE_MS)


static func _buzz(ms: int) -> void:
	if not SaveData.haptics_on:
		return
	Input.vibrate_handheld(ms)
