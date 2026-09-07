extends Node3D
## Kedai Runtuh — main game loop.
##
## One tap drops whatever is hanging from the hook. It falls, lands on the tower,
## and the camera rises. Miss the tower, or knock it over, and the run ends.
##
## To add new food: add a line to the ITEMS list below. Nothing else to change.

# ---------------------------------------------------------------------------
# THE FOOD. This is the list you edit.
#
#   name   — for your own reference while reading the list
#   shape  — "cylinder" (round things) or "box" (square things)
#   size   — x = width, y = height, z = depth, in metres.
#            Keep every footprint (x and z) between about 0.8 and 1.05. If one
#            item is much narrower than the rest it becomes an impossible base
#            and the run ends whenever it turns up. Vary the HEIGHT, not the width.
#   color  — placeholder colour, used until you set a model
#   model  — leave "" for now. When you download a Sketchfab .glb into
#            assets/models/, put its path here, e.g. "res://assets/models/teh.glb"
# ---------------------------------------------------------------------------
const ITEMS: Array[Dictionary] = [
	{"name": "Pinggan",       "shape": "cylinder", "size": Vector3(1.00, 0.16, 1.00), "color": Color("f4f1ea"), "model": ""},
	{"name": "Mangkuk",       "shape": "cylinder", "size": Vector3(0.90, 0.42, 0.90), "color": Color("e3d3b4"), "model": ""},
	{"name": "Gelas teh",     "shape": "cylinder", "size": Vector3(0.80, 0.60, 0.80), "color": Color("c9863f"), "model": ""},
	{"name": "Roti canai",    "shape": "box",      "size": Vector3(1.05, 0.22, 1.05), "color": Color("dba441"), "model": ""},
	{"name": "Kotak bungkus", "shape": "box",      "size": Vector3(0.95, 0.50, 0.95), "color": Color("b5563c"), "model": ""},
]

# How the game feels. Tweak these first when something plays wrong.
const DROP_HEIGHT := 1.4      ## how far above the tower the hook hangs
const FALL_MARGIN := 1.8      ## fall this far below the table and it is gone
const SETTLE_SPEED := 0.30    ## slower than this counts as "stopped moving"
const SETTLE_TIME := 0.35     ## must stay still this long before it counts
const MAX_DROP_TIME := 5.0    ## give up waiting after this and judge it anyway
const LIVE_PIECES := 2        ## how many pieces at the top stay physically live
const GAME_OVER_DELAY := 1.2  ## seconds to watch the tower fall before the panel shows
const LANDING_TOLERANCE := 0.55 ## how far below the tower top still counts as "on top"
const TABLE_TOP := 0.0        ## the table surface sits at y = 0

enum State { AIMING, DROPPING, OVER }

var state: State = State.AIMING
var score := 0
var best := 0
var highest_y := 0.0          ## top of the tower right now
var settle_timer := 0.0
var drop_timer := 0.0
var next_item := {}
var active_piece: RigidBody3D = null

@onready var hook: Node3D = $Hook
@onready var preview: MeshInstance3D = $Hook/Preview
@onready var pieces: Node3D = $Pieces
@onready var camera_rig: Node3D = $CameraRig
@onready var score_label: Label = $UI/Score
@onready var hint_label: Label = $UI/Hint
@onready var game_over_panel: Control = $UI/GameOver
@onready var result_label: Label = $UI/GameOver/Result


func _ready() -> void:
	best = _load_best()
	game_over_panel.hide()
	$UI/GameOver/Again.pressed.connect(_restart)
	_arm_next_item()


func _unhandled_input(event: InputEvent) -> void:
	var tapped := false
	if event is InputEventScreenTouch and event.pressed:
		tapped = true
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		tapped = true
	elif event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_SPACE:
		tapped = true

	if not tapped:
		return

	if state == State.AIMING:
		_drop()
	elif state == State.OVER and game_over_panel.visible:
		# Ignore taps while the tower is still coming down, so a fast tapper
		# does not skip past the collapse they just caused.
		_restart()


func _process(delta: float) -> void:
	_follow_tower(delta)

	# Anything falling off the table ends the run — that is also how a
	# collapse gets caught, because a collapse throws pieces off the edge.
	for p in pieces.get_children():
		if p.global_position.y < TABLE_TOP - FALL_MARGIN:
			if state != State.OVER:
				_game_over("JATUH!")
			return

	if state != State.DROPPING or active_piece == null:
		return

	drop_timer += delta
	var still := active_piece.linear_velocity.length() < SETTLE_SPEED \
			and active_piece.angular_velocity.length() < SETTLE_SPEED * 3.0

	if still:
		settle_timer += delta
		if settle_timer >= SETTLE_TIME:
			_resolve_landing()
	else:
		settle_timer = 0.0
		# Stacked bodies can jitter against each other forever. Rather than
		# hang the game waiting for perfect stillness, judge it and move on.
		if drop_timer >= MAX_DROP_TIME:
			_resolve_landing()


## The camera glides up to the top of the tower. The hook does NOT glide — it
## snaps, so the piece always falls from exactly DROP_HEIGHT above the stack.
## When the hook glided too, tapping quickly after a landing spawned the piece
## from too low down, sometimes inside the tower.
func _follow_tower(delta: float) -> void:
	camera_rig.position.y = lerp(camera_rig.position.y, highest_y + 1.6, delta * 3.0)
	hook.position.y = highest_y + DROP_HEIGHT


## Pick the next piece of food and show it hanging from the hook.
func _arm_next_item() -> void:
	next_item = ITEMS[randi() % ITEMS.size()]
	preview.mesh = _make_mesh(next_item)
	preview.material_override = _make_material(next_item.color)
	preview.show()
	state = State.AIMING


## Turn the hanging preview into a real falling object.
func _drop() -> void:
	preview.hide()

	var body := RigidBody3D.new()
	body.mass = next_item.size.x * next_item.size.y * 6.0
	body.continuous_cd = true
	# Damping bleeds off the skid so a piece settles where it lands instead of
	# sliding across the tower and off the edge.
	body.linear_damp = 1.0
	body.angular_damp = 3.0
	# Lock it to a flat plane so the game stays readable from the side —
	# nothing drifts toward or away from the camera, nothing spins sideways.
	body.axis_lock_linear_z = true
	body.axis_lock_angular_x = true
	body.axis_lock_angular_y = true

	var mat := PhysicsMaterial.new()
	mat.friction = 2.0
	mat.rough = true
	mat.bounce = 0.0
	body.physics_material_override = mat

	var mesh_node := MeshInstance3D.new()
	mesh_node.name = "Mesh"
	mesh_node.mesh = _make_mesh(next_item)
	mesh_node.material_override = _make_material(next_item.color)
	body.add_child(mesh_node)

	var shape_node := CollisionShape3D.new()
	shape_node.shape = _make_shape(next_item)
	body.add_child(shape_node)

	pieces.add_child(body)
	body.global_position = preview.global_position

	active_piece = body
	settle_timer = 0.0
	drop_timer = 0.0
	state = State.DROPPING


## The piece has stopped. Did it land on top of the tower, or slide down it?
func _resolve_landing() -> void:
	var box := _world_box(active_piece)
	var bottom := box.position.y
	var tower_top := _tower_top(active_piece)

	# The piece has to come to rest near the top of the tower. If it ended up
	# well below that, it slid down the side or missed onto the table — either
	# way it is not stacked, and the run is over.
	if score > 0 and bottom < tower_top - LANDING_TOLERANCE:
		_game_over("TERSASAR!")
		return

	score += 1
	score_label.text = str(score)
	hint_label.hide()
	# Measured fresh every time, so the tower height drops back down if the
	# stack settles instead of getting stuck at an old high-water mark.
	highest_y = max(tower_top, box.position.y + box.size.y)

	# The swing gets faster the higher you go. This is the whole difficulty curve.
	hook.speed = hook.base_speed + min(score, 30) * 0.055

	_settle_tower()
	active_piece = null
	_arm_next_item()


func _game_over(reason: String) -> void:
	state = State.OVER
	active_piece = null
	preview.hide()
	_collapse_tower()

	if score > best:
		best = score
		_save_best(best)

	result_label.text = "%s\n\n%d tersusun\nterbaik: %d\n\ntap to try again" % [reason, score, best]

	# Let the tower actually go over before the panel covers it. This second and
	# a bit is the shot people record, so it is worth waiting for.
	await get_tree().create_timer(GAME_OVER_DELAY).timeout
	if is_inside_tree():
		game_over_panel.show()


## Losing unsticks the whole tower and gives it a shove, so every run ends with
## the thing actually coming down. During play the lower pieces are frozen so the
## tower is fair to build on; that only stops applying once you have lost.
func _collapse_tower() -> void:
	var highest: RigidBody3D = null
	var top := -INF
	for p in pieces.get_children():
		var body: RigidBody3D = p
		body.freeze = false
		body.sleeping = false
		var b := _world_box(body)
		if b.position.y + b.size.y > top:
			top = b.position.y + b.size.y
			highest = body
	if highest != null:
		var push := 1.0 if randf() < 0.5 else -1.0
		highest.apply_impulse(Vector3(push * highest.mass * 1.6, 0.0, 0.0))


func _restart() -> void:
	get_tree().reload_current_scene()


# --- building blocks -------------------------------------------------------

## Pieces far below the top are frozen solid so the tower cannot drift or creep.
## Only the newest few stay live — that is enough for the top to still collapse,
## which is the whole point of the game, without the base wandering off the table.
func _settle_tower() -> void:
	var kids := pieces.get_children()
	for i in kids.size():
		var body: RigidBody3D = kids[i]
		body.freeze = i < kids.size() - LIVE_PIECES


## Height of the tallest settled piece, ignoring the one still being judged.
func _tower_top(exclude: RigidBody3D) -> float:
	var t := TABLE_TOP
	for p in pieces.get_children():
		if p == exclude:
			continue
		var b := _world_box(p)
		t = max(t, b.position.y + b.size.y)
	return t


## The real space a piece occupies right now, rotation included.
func _world_box(body: RigidBody3D) -> AABB:
	var mesh_node: MeshInstance3D = body.get_node("Mesh")
	return mesh_node.global_transform * mesh_node.get_aabb()


func _make_mesh(item: Dictionary) -> Mesh:
	if item.shape == "cylinder":
		var cyl := CylinderMesh.new()
		cyl.top_radius = item.size.x * 0.5
		cyl.bottom_radius = item.size.x * 0.5
		cyl.height = item.size.y
		return cyl
	var box := BoxMesh.new()
	box.size = item.size
	return box


func _make_shape(item: Dictionary) -> Shape3D:
	if item.shape == "cylinder":
		var cyl := CylinderShape3D.new()
		cyl.radius = item.size.x * 0.5
		cyl.height = item.size.y
		return cyl
	var box := BoxShape3D.new()
	box.size = item.size
	return box


func _make_material(color: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.75
	return mat


# --- best score, kept between sessions -------------------------------------

const SAVE_PATH := "user://kedai_runtuh.cfg"

func _load_best() -> int:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return 0
	return int(cfg.get_value("score", "best", 0))


func _save_best(value: int) -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("score", "best", value)
	cfg.save(SAVE_PATH)
