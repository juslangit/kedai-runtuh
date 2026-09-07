extends Node3D
## The hook that swings above the tower.
##
## It only moves left and right. Its height is set by game.gd, which keeps it
## a fixed distance above the top of the tower.

@export var swing_range := 1.8   ## how far it travels either side of centre
@export var base_speed := 1.4    ## swings per second at the start

var speed := base_speed
var _t := 0.0


func _ready() -> void:
	speed = base_speed
	# Start off-centre so the first drop still needs a decision.
	_t = randf() * TAU


func _process(delta: float) -> void:
	_t += delta * speed
	position.x = sin(_t) * swing_range
