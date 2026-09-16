extends Node3D
## The mamak stall the game is played in: painted layers around a round marble
## table. Used by both the main menu and the game, so they are the same place.
##
## It works like matte-painting cards on a film set. Each painting is a flat card
## standing at a different distance from the camera:
##
##   Sky         — furthest back, and it FOLLOWS the camera, so there is always
##                 sky however high the tower gets
##   Street      — the stall, shophouses and palm trees; stays put, so it scrolls
##                 away below as the camera climbs
##   Canopy      — the zinc roof overhead; the tower climbs up past it
##   Foreground  — the stools nearest the camera; closest, so it moves fastest
##
## Because the cards are at different distances they slide past each other at
## different speeds as the camera rises, which is what gives the flat paintings
## depth. To move a card, move its node in the editor — nothing here depends on
## where they are, and none of it touches the physics.

## How much the sky sinks as the camera climbs. 0 = the sky is glued to the
## camera, higher = the clouds drift down past you. Kept small, because the sky
## card is only a little taller than the screen.
@export var sky_drift := 0.04
## The furthest the sky may sink, in metres, before it would show its edge.
@export var sky_drift_limit := 1.0

@onready var _sky: Sprite3D = $Sky

var _start_y := NAN


func _process(_delta: float) -> void:
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		return
	var y := camera.global_position.y
	if is_nan(_start_y):
		_start_y = y
	var sink := clampf((y - _start_y) * sky_drift, 0.0, sky_drift_limit)
	_sky.global_position.y = y - sink
