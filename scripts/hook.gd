extends Node3D
## The hook the food hangs from.
##
## It is a real pendulum. It swings through an ARC around the pivot above the
## table, so the food rises a little at the ends of the swing instead of sliding
## along a flat line, and it hangs at an angle rather than staying bolt upright.
##
## The angle is driven by a sine wave rather than simulated. A simulated pendulum
## bleeds off energy and would need pushing to keep going, and the swing speed is
## the game's whole difficulty curve — it has to be exact, not approximately right.

@export var swing_degrees := 28.0  ## how far it swings either side of straight down
@export var base_speed := 1.4      ## swings per second at the start

var speed := base_speed
var pivot := Vector3.ZERO  ## where it hangs from; set by the game each frame
var length := 3.8          ## pivot to food, set by the game each frame
var angle := 0.0           ## rope angle in radians, 0 = hanging straight down

var _t := 0.0


func _ready() -> void:
	speed = base_speed
	# Start part-way through a swing so the first drop still needs a decision.
	_t = randf() * TAU


func _process(delta: float) -> void:
	_t += delta * speed
	angle = deg_to_rad(swing_degrees) * sin(_t)
	# Position on the arc, not on a horizontal line.
	position = pivot + Vector3(sin(angle), -cos(angle), 0.0) * length
	# Whatever is hanging leans with the rope, the way a real hanging thing does.
	rotation.z = angle
