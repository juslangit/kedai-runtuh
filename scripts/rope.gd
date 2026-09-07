extends Node3D
## A soft rope hanging from a fixed pivot down to the swinging hook.
##
## The top never moves — it stays at the middle of the screen. The bottom is
## pinned to wherever the hook is, and everything in between is simulated, so the
## rope bends, lags behind the swing and settles instead of being a stiff stick.
##
## This is PURELY DECORATION. The game never reads the rope's position; the piece
## still hangs exactly where the hook says. So none of the numbers below can
## change how the game plays — tune them until it looks right.

@export var segments := 16        ## more = smoother rope, slightly more work
@export var thickness := 0.045
@export var rope_gravity := 15.0  ## how heavily it hangs
@export var damping := 0.86       ## lower = the wobble dies out faster
@export var slack := 1.012       ## rope is this much longer than the straight line
@export var solver_passes := 8    ## more = less rubbery, holds its length better

var _points := PackedVector3Array()
var _prev := PackedVector3Array()
var _links: Array[MeshInstance3D] = []
var _anchor := Vector3.ZERO
var _tip := Vector3.ZERO
var _seg_len := 0.25
var _started := false


func _ready() -> void:
	var mesh := CylinderMesh.new()
	mesh.top_radius = thickness
	mesh.bottom_radius = thickness
	mesh.height = 1.0
	mesh.radial_segments = 6
	mesh.rings = 0
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.243, 0.196, 0.176)
	mat.roughness = 1.0

	for i in segments:
		var link := MeshInstance3D.new()
		link.mesh = mesh
		link.material_override = mat
		add_child(link)
		_links.append(link)

	_points.resize(segments + 1)
	_prev.resize(segments + 1)


## Called every frame by the game: where the rope hangs from, and where it ends.
func set_endpoints(anchor: Vector3, tip: Vector3) -> void:
	_anchor = anchor
	_tip = tip
	_seg_len = maxf(anchor.distance_to(tip) * slack, 0.01) / float(segments)
	if not _started:
		_snap_straight()
		_started = true


## Lay the rope out in a straight line — used once, before it has any history.
func _snap_straight() -> void:
	for i in _points.size():
		var t := float(i) / float(segments)
		_points[i] = _anchor.lerp(_tip, t)
		_prev[i] = _points[i]


func _physics_process(delta: float) -> void:
	if not _started:
		return

	# Verlet: each point keeps moving the way it was already moving, plus gravity.
	# That memory of the last frame is what makes the rope trail behind the swing.
	var last := _points.size() - 1
	for i in range(1, last):
		var here := _points[i]
		var velocity := (here - _prev[i]) * damping
		_prev[i] = here
		_points[i] = here + velocity + Vector3(0.0, -rope_gravity, 0.0) * delta * delta

	# The two ends are not free — they are nailed to the pivot and the hook.
	_points[0] = _anchor
	_points[last] = _tip

	# Pull neighbouring points back to the right distance apart, repeatedly.
	# One pass leaves it stretchy; several make it read as a rope.
	for _pass in solver_passes:
		for i in last:
			var a := _points[i]
			var b := _points[i + 1]
			var delta_v := b - a
			var dist := delta_v.length()
			if dist < 0.00001:
				continue
			var error := (dist - _seg_len) / dist
			# A pinned end cannot move, so its neighbour takes the whole correction.
			var free_a := 0.0 if i == 0 else 1.0
			var free_b := 0.0 if i + 1 == last else 1.0
			var total := free_a + free_b
			if total == 0.0:
				continue
			_points[i] = a + delta_v * error * (free_a / total)
			_points[i + 1] = b - delta_v * error * (free_b / total)

	# The whole game is played on a flat plane, so keep the rope on it too.
	for i in _points.size():
		var p := _points[i]
		p.z = 0.0
		_points[i] = p

	_draw()


## Stretch one cylinder between each pair of points.
func _draw() -> void:
	for i in _links.size():
		var a := _points[i]
		var b := _points[i + 1]
		var span := b - a
		var length := span.length()
		if length < 0.00001:
			_links[i].visible = false
			continue
		_links[i].visible = true
		_links[i].transform = Transform3D(
			_aim_y_along(span) * Basis.from_scale(Vector3(1.0, length, 1.0)),
			(a + b) * 0.5)


## A cylinder mesh points along its own Y. Turn it to point along `dir` instead.
func _aim_y_along(dir: Vector3) -> Basis:
	var up := dir.normalized()
	var axis := Vector3.UP.cross(up)
	if axis.length() < 0.00001:
		return Basis.IDENTITY if up.y > 0.0 else Basis(Vector3.RIGHT, PI)
	return Basis(axis.normalized(), Vector3.UP.angle_to(up))
