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
#   name   — shown on the hook and in your own reading of the list
#   shape  — the COLLISION shape: "cylinder" (round) or "box" (square)
#   width  — footprint in metres. Keep every item between about 0.80 and 1.05.
#            If one item is much narrower than the rest it becomes an impossible
#            base and the run ends whenever it turns up.
#   height — how tall the piece is in metres.
#   color  — only used when there is no model
#   model  — the imported file the mesh comes from
#   node   — the name of the object inside that file
#
# width and height are the real physics box. The model is SCALED TO FIT them, not
# the other way round — so changing a model never changes how the game plays.
# ---------------------------------------------------------------------------
const CAFE := "res://assets/models/cafe_props/scene.gltf"

## tier 0 = flat and forgiving, 1 = middling, 2 = tall and awkward.
## The mix shifts towards the higher tiers as the tower grows.
const ITEMS: Array[Dictionary] = [
	{"name": "Plate",         "tier": 0, "shape": "cylinder", "width": 1.00, "height": 0.16, "color": Color("f4f1ea"), "model": CAFE, "node": "Plate_big_Dishes_0"},
	{"name": "Small plate",   "tier": 0, "shape": "cylinder", "width": 0.88, "height": 0.14, "color": Color("f0ece2"), "model": CAFE, "node": "Plate_small_Dishes_0"},
	{"name": "Food tray",     "tier": 0, "shape": "box",      "width": 1.05, "height": 0.15, "color": Color("d9cdb5"), "model": CAFE, "node": "Food_tray_Dishes_0"},
	{"name": "Fried egg",     "tier": 0, "shape": "cylinder", "width": 1.05, "height": 0.22, "color": Color("f3e2b0"), "model": CAFE, "node": "Egg_Food_0"},
	{"name": "Table sign",    "tier": 1, "shape": "box",      "width": 0.95, "height": 0.36, "color": Color("c8b48a"), "model": CAFE, "node": "Reserved_table_sign_Extra_objects_0"},
	{"name": "Doughnut",      "tier": 1, "shape": "cylinder", "width": 0.85, "height": 0.35, "color": Color("c98b4b"), "model": CAFE, "node": "Donut_brown_Food_0"},
	{"name": "Pink doughnut", "tier": 1, "shape": "cylinder", "width": 0.85, "height": 0.35, "color": Color("e8a0b4"), "model": CAFE, "node": "Donut_pink_Food_0"},
	{"name": "Bowl",          "tier": 1, "shape": "cylinder", "width": 0.90, "height": 0.42, "color": Color("e3d3b4"), "model": CAFE, "node": "Bowl_Sauces_0"},
	{"name": "Sauce bowl",    "tier": 1, "shape": "cylinder", "width": 0.86, "height": 0.40, "color": Color("dcc9a6"), "model": CAFE, "node": "Bowl_001_Sauces_0"},
	{"name": "Burger bun",    "tier": 1, "shape": "cylinder", "width": 0.85, "height": 0.44, "color": Color("d79b52"), "model": CAFE, "node": "Burger_top_Food_0"},
	{"name": "Service bell",  "tier": 1, "shape": "cylinder", "width": 0.80, "height": 0.42, "color": Color("cfa94e"), "model": CAFE, "node": "Bell_Extra_objects_0"},
	{"name": "Little plant",  "tier": 2, "shape": "cylinder", "width": 0.85, "height": 0.46, "color": Color("7fa05a"), "model": CAFE, "node": "Plant_Extra_objects_0"},
	{"name": "Takeaway box",  "tier": 2, "shape": "box",      "width": 0.95, "height": 0.50, "color": Color("b5563c"), "model": CAFE, "node": "Carton_Food_0"},
	{"name": "Coffee cup",    "tier": 2, "shape": "cylinder", "width": 0.85, "height": 0.55, "color": Color("b8763c"), "model": CAFE, "node": "Cup_Drinks_0"},
	{"name": "Cup",           "tier": 2, "shape": "cylinder", "width": 0.80, "height": 0.60, "color": Color("c9863f"), "model": CAFE, "node": "Cup_002_Drinks_0"},
	{"name": "Tall cup",      "tier": 2, "shape": "cylinder", "width": 0.82, "height": 0.62, "color": Color("d1a05a"), "model": CAFE, "node": "Cup_001_Drinks_0"},
]

## How likely each tier is, by how many pieces are already stacked. Flat things
## early, awkward things once the tower is tall.
const TIER_WEIGHTS := {
	"early": [3.0, 2.0, 0.6],
	"mid":   [1.5, 2.0, 1.5],
	"late":  [0.6, 1.5, 2.5],
}
const EARLY_UNTIL := 5   ## pieces stacked below this count as "early"
const MID_UNTIL := 11
const RECENT_MEMORY := 3 ## do not offer anything from the last this-many drops

# How the game feels. Tweak these first when something plays wrong.
const DROP_HEIGHT := 1.4      ## how far above the tower the hook hangs
const FALL_MARGIN := 1.8      ## fall this far below the table and it is gone
const SETTLE_SPEED := 0.55    ## slower than this counts as "stopped moving"
const SETTLE_TIME := 0.30     ## must stay still this long before it counts
const MAX_DROP_TIME := 2.5    ## give up waiting after this and judge it anyway
const LIVE_PIECES := 2        ## how many pieces at the top stay physically live
const GAME_OVER_DELAY := 1.9  ## real seconds to watch the tower fall before the panel
const ANCHOR_HEIGHT := 5.2    ## how high above the tower the rope is pinned
const PERFECT_WINDOW := 0.28  ## land this close to the centre below and it is a PERFECT
const PERFECT_POINTS := 2     ## what a perfect landing is worth instead of 1
const WOBBLE_LEAN := 0.55     ## tower leaning more than this starts creaking
const SLOWMO_SCALE := 0.32    ## how far time slows during the collapse
const SHAKE_LAND := 0.035
const SHAKE_COLLAPSE := 0.42
const RIGHTING_START := 25.0  ## degrees of lean before a piece is nudged upright
const RIGHTING_FORCE := 2.0   ## how hard that nudge is
const RIGHTING_DAMPING := 2.5 ## resists spin, so the nudge settles instead of buzzing
const DROP_TILT := 1.0        ## how much of the rope's lean the piece keeps once released
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

## name -> {mesh, transform} for every item that has a model, worked out once at
## startup so a piece can be built without touching the source file again.
var _visuals := {}

## Camera shake, and the height the camera would sit at without it.
var shake := 0.0
var _cam_base_y := 0.0
var _creak_timer := 0.0

## The last few items handed out, so the same thing does not keep appearing.
var _recent: Array[String] = []

@onready var hook: Node3D = $Hook
@onready var rope: Node3D = $Rope
@onready var pivot: Node3D = $Pivot
@onready var preview: MeshInstance3D = $Hook/Preview
@onready var pieces: Node3D = $Pieces
@onready var camera_rig: Node3D = $CameraRig
@onready var ui: CanvasLayer = $UI
@onready var hud: Control = $UI/Hud
@onready var score_label: Label = $UI/Hud/Scores/ScoreValue
@onready var hud_best_label: Label = $UI/Hud/Scores/BestValue
@onready var hint_label: Label = $UI/Hud/Hint
@onready var pause_button: Button = $UI/Hud/Pause
@onready var pause_menu: Control = $UI/PauseMenu
@onready var settings_panel: Control = $UI/SettingsPanel
@onready var game_over_panel: Control = $UI/GameOver
@onready var reason_label: Label = $UI/GameOver/Center/Panel/Box/Reason
@onready var new_best_label: Label = $UI/GameOver/Center/Panel/Box/NewBest


func _ready() -> void:
	# Run even while the tree is paused, so the pause menu can be opened and
	# closed. _process bails out immediately when paused, so nothing moves.
	process_mode = Node.PROCESS_MODE_ALWAYS
	ui.process_mode = Node.PROCESS_MODE_ALWAYS
	hud.theme = UITheme.get_theme()
	pause_menu.theme = UITheme.get_theme()
	game_over_panel.theme = UITheme.get_theme()
	pause_button.icon = UITheme.pause_icon(52, UITheme.BROWN)

	_prepare_models()
	best = SaveData.high_score
	hud_best_label.text = str(best)
	pause_menu.hide()
	game_over_panel.hide()

	pause_button.pressed.connect(_pause)
	$UI/PauseMenu/Center/Panel/Box/Resume.pressed.connect(_resume)
	$UI/PauseMenu/Center/Panel/Box/Restart.pressed.connect(_restart)
	$UI/PauseMenu/Center/Panel/Box/MainMenu.pressed.connect(_to_main_menu)
	$UI/PauseMenu/Center/Panel/Box/Settings.pressed.connect(settings_panel.open)
	# the best score can be erased in settings, so re-read it on the way back
	settings_panel.closed.connect(_refresh_pause_scores)
	$UI/GameOver/Center/Panel/Box/Again.pressed.connect(_restart)
	$UI/GameOver/Center/Panel/Box/MainMenu.pressed.connect(_to_main_menu)

	_cam_base_y = camera_rig.position.y
	Engine.time_scale = 1.0
	Audio.wire_buttons(ui)
	Audio.start_music()

	_arm_next_item()


func _unhandled_input(event: InputEvent) -> void:
	# Escape on desktop, the back button on Android.
	if event.is_action_pressed("ui_cancel"):
		if get_tree().paused:
			_resume()
		elif state != State.OVER:
			_pause()
		get_viewport().set_input_as_handled()
		return

	var tapped := false
	if event is InputEventScreenTouch and event.pressed:
		tapped = true
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		tapped = true
	elif event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_SPACE:
		tapped = true

	if not tapped:
		return
	# While the pause menu is up, taps belong to its buttons, not to the game.
	if get_tree().paused:
		return

	if state == State.AIMING:
		_drop()


func _process(delta: float) -> void:
	if get_tree().paused:
		return
	_follow_tower(delta)

	# Anything falling off the table ends the run — that is also how a
	# collapse gets caught, because a collapse throws pieces off the edge.
	for p in pieces.get_children():
		if p.global_position.y < TABLE_TOP - FALL_MARGIN:
			if state != State.OVER:
				_game_over("TOPPLED!")
			return

	_creak_if_leaning(delta)

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


## Nudge a badly leaning piece back towards flat.
##
## Pieces can only rotate in the plane of the screen, so a plate turned on its
## side is stable in a way a real plate never is — it cannot fall over sideways,
## because sideways has been locked out. This puts back the force that the lock
## removed: nothing below 25 degrees, then a push that grows the further past it
## goes. Pieces still tilt and still look precarious; they just stop balancing on
## their rim forever.
func _physics_process(_delta: float) -> void:
	# Only the piece currently falling is ever nudged, and only while it is still
	# being judged. A tower that has settled is never touched again, which is what
	# stops the nudge turning into a permanent buzz.
	if state != State.DROPPING or active_piece == null:
		return
	if active_piece.freeze or active_piece.sleeping:
		return

	var lean: float = active_piece.rotation.z
	var past: float = absf(lean) - deg_to_rad(RIGHTING_START)
	if past <= 0.0:
		return
	var spring: float = -signf(lean) * past * RIGHTING_FORCE
	var damper: float = -active_piece.angular_velocity.z * RIGHTING_DAMPING
	active_piece.apply_torque(Vector3(0.0, 0.0, (spring + damper) * active_piece.mass))


## A leaning tower groans. This is a warning, not decoration — it tells the player
## their next drop matters, and turns a sudden loss into one they saw coming.
func _creak_if_leaning(delta: float) -> void:
	if state == State.OVER or pieces.get_child_count() < 2:
		return
	if _tower_lean() <= WOBBLE_LEAN:
		_creak_timer = 0.0
		return
	_creak_timer -= delta
	if _creak_timer <= 0.0:
		_creak_timer = randf_range(0.5, 0.95)
		Audio.play("creak", randf_range(0.5, 0.7), 0.05, -9.0)
		shake = maxf(shake, 0.018)


## How far the top of the tower has wandered sideways from its base.
func _tower_lean() -> float:
	var kids := pieces.get_children()
	if kids.size() < 2:
		return 0.0
	var top := _highest_piece(null)
	if top == null:
		return 0.0
	return absf(_world_box(top).get_center().x - _world_box(kids[0]).get_center().x)


## The piece currently on top, ignoring one that is still being judged.
func _highest_piece(exclude) -> RigidBody3D:
	var best: RigidBody3D = null
	var best_top := -INF
	for p in pieces.get_children():
		if p == exclude:
			continue
		var b := _world_box(p)
		if b.position.y + b.size.y > best_top:
			best_top = b.position.y + b.size.y
			best = p
	return best


## The camera glides up to the top of the tower. The hook does NOT glide — it
## snaps, so the piece always falls from exactly DROP_HEIGHT above the stack.
## When the hook glided too, tapping quickly after a landing spawned the piece
## from too low down, sometimes inside the tower.
func _follow_tower(delta: float) -> void:
	_cam_base_y = lerp(_cam_base_y, highest_y + 1.5, delta * 3.0)
	shake = move_toward(shake, 0.0, delta * 1.6)
	camera_rig.position = Vector3(
			randf_range(-shake, shake),
			_cam_base_y + randf_range(-shake, shake),
			0.0)
	# The rope hangs from a fixed point straight above the middle of the table.
	# Only its bottom end moves, because the hook swings around this pivot.
	pivot.position = Vector3(0.0, highest_y + ANCHOR_HEIGHT, 0.0)
	hook.pivot = pivot.position
	hook.length = ANCHOR_HEIGHT - DROP_HEIGHT
	# End the rope at the TOP of whatever is hanging, not at its middle, so it
	# looks tied on rather than skewered through.
	var tie_on := 0.0
	if state == State.AIMING and not next_item.is_empty():
		tie_on = float(next_item.height) * 0.5
	# Along the rope's own direction, not straight up, now that the hook leans.
	rope.set_endpoints(pivot.position,
			hook.global_position + hook.global_transform.basis.y * tie_on)


## Pick the next piece of food and show it hanging from the hook.
func _arm_next_item() -> void:
	next_item = _pick_item()
	_apply_visual(preview, next_item)
	preview.show()
	state = State.AIMING


## Choose the next piece: weighted towards awkward shapes as the tower grows, and
## never something handed out in the last few drops.
func _pick_item() -> Dictionary:
	var stacked := pieces.get_child_count()
	var weights: Array = TIER_WEIGHTS.late
	if stacked < EARLY_UNTIL:
		weights = TIER_WEIGHTS.early
	elif stacked < MID_UNTIL:
		weights = TIER_WEIGHTS.mid

	var pool: Array[Dictionary] = []
	var total := 0.0
	for item in ITEMS:
		if item.name in _recent:
			continue
		pool.append(item)
		total += float(weights[int(item.tier)])
	if pool.is_empty():
		pool = ITEMS.duplicate()
		total = 0.0
		for item in pool:
			total += float(weights[int(item.tier)])

	var roll := randf() * total
	var chosen: Dictionary = pool[pool.size() - 1]
	for item in pool:
		roll -= float(weights[int(item.tier)])
		if roll <= 0.0:
			chosen = item
			break

	_recent.append(chosen.name)
	while _recent.size() > RECENT_MEMORY:
		_recent.pop_front()
	return chosen


## Turn the hanging preview into a real falling object.
func _drop() -> void:
	preview.hide()

	var body := RigidBody3D.new()
	body.mass = next_item.width * next_item.height * 6.0
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
	body.add_child(mesh_node)
	_apply_visual(mesh_node, next_item)

	var shape_node := CollisionShape3D.new()
	shape_node.shape = _make_shape(next_item)
	body.add_child(shape_node)

	pieces.add_child(body)
	body.global_position = hook.global_position
	# How much of the hanging lean the piece keeps once it is let go.
	body.rotation.z = hook.angle * DROP_TILT

	Audio.play("release", 1.05, 0.06, -6.0)
	Haptics.tap()

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
		_game_over("MISSED!")
		return

	# Landing dead centre on the piece below is a PERFECT, and worth double.
	var perfect := false
	var below := _highest_piece(active_piece)
	if below != null:
		perfect = absf(box.get_center().x - _world_box(below).get_center().x) <= PERFECT_WINDOW

	# Small light things land higher and sharper than big heavy ones.
	Audio.play("land", clampf(1.5 - float(next_item.height), 0.8, 1.35), 0.08)
	Haptics.land()
	shake = maxf(shake, SHAKE_LAND)

	score += PERFECT_POINTS if perfect else 1
	score_label.text = str(score)
	hint_label.hide()
	if perfect:
		_celebrate_perfect()

	# Measured fresh every time, so the tower height drops back down if the
	# stack settles instead of getting stuck at an old high-water mark.
	highest_y = max(tower_top, box.position.y + box.size.y)

	# The swing gets faster the higher you go — counted in PIECES, not points, so
	# that changing what a perfect is worth never changes the difficulty curve.
	hook.speed = hook.base_speed + min(pieces.get_child_count(), 30) * 0.055

	active_piece.sleeping = true
	_settle_tower()
	active_piece = null
	_arm_next_item()


func _game_over(reason: String) -> void:
	state = State.OVER
	active_piece = null
	preview.hide()
	pause_button.hide()
	_collapse_tower()

	# The collapse is the moment people record, so it gets the full treatment:
	# time slows, the camera shakes, and the dishes go in waves rather than one
	# tidy thud.
	if reason == "MISSED!":
		Audio.play("miss", 1.0, 0.02, -5.0)
	Audio.play_crash()
	Haptics.collapse()
	shake = SHAKE_COLLAPSE
	Engine.time_scale = SLOWMO_SCALE

	# The record lives in SaveData, not in this scene, so restarting cannot
	# reset it — a fresh scene simply reads the same stored number back.
	var is_record: bool = SaveData.submit_score(score)
	best = SaveData.high_score

	reason_label.text = reason
	new_best_label.visible = is_record
	$UI/GameOver/Center/Panel/Box/Scores/Current/Value.text = str(score)
	$UI/GameOver/Center/Panel/Box/Scores/Best/Value.text = str(best)
	hud_best_label.text = str(best)

	# Let the tower actually go over before the panel covers it. This second and
	# a bit is the shot people record, so it is worth waiting for.
	# ignore_time_scale, or the slow motion would stretch this wait too.
	await get_tree().create_timer(GAME_OVER_DELAY, true, false, true).timeout
	Engine.time_scale = 1.0
	if is_inside_tree():
		game_over_panel.show()
		$UI/GameOver/Center/Panel/Box/Again.grab_focus()


# --- pause -----------------------------------------------------------------

func _pause() -> void:
	if state == State.OVER or get_tree().paused:
		return
	_refresh_pause_scores()
	pause_menu.show()
	get_tree().paused = true
	$UI/PauseMenu/Center/Panel/Box/Resume.grab_focus()


func _resume() -> void:
	Engine.time_scale = 1.0
	get_tree().paused = false
	pause_menu.hide()


func _to_main_menu() -> void:
	Engine.time_scale = 1.0
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")


func _refresh_pause_scores() -> void:
	$UI/PauseMenu/Center/Panel/Box/Scores/Current/Value.text = str(score)
	$UI/PauseMenu/Center/Panel/Box/Scores/Best/Value.text = str(SaveData.high_score)
	best = SaveData.high_score
	hud_best_label.text = str(best)


## A white blink and a word, for landing it dead centre.
func _celebrate_perfect() -> void:
	Audio.play("perfect", 1.0, 0.02)
	Haptics.perfect()
	shake = maxf(shake, 0.05)

	var flash: ColorRect = $UI/Hud/Flash
	var flash_tween := create_tween()
	flash_tween.tween_property(flash, "color:a", 0.30, 0.04)
	flash_tween.tween_property(flash, "color:a", 0.0, 0.32)

	var label: Label = $UI/Hud/Perfect
	label.modulate.a = 1.0
	var label_tween := create_tween()
	label_tween.tween_interval(0.35)
	label_tween.tween_property(label, "modulate:a", 0.0, 0.45)


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
	Engine.time_scale = 1.0
	get_tree().paused = false
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
		if not body.freeze:
			# The drop is over and the stack has been judged still, so the live
			# pieces are told to sleep. Left awake they grind against each other
			# at a speed too small to see as movement but big enough to look like
			# a buzz. Godot wakes them the instant anything touches them, so the
			# next landing still knocks the tower about exactly as before.
			body.sleeping = true


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


## Work out, once, how each model has to be scaled and shifted to sit exactly
## inside its physics box. Done at startup so no piece ever loads a file mid-game.
func _prepare_models() -> void:
	var opened := {}
	for item in ITEMS:
		if String(item.get("model", "")) == "":
			continue
		if not opened.has(item.model):
			var packed: PackedScene = load(item.model)
			if packed == null:
				push_warning("Cannot load model file: %s" % item.model)
				continue
			opened[item.model] = packed.instantiate()
		var found := (opened[item.model] as Node).find_child(item.node, true, false)
		if found == null or not (found is MeshInstance3D):
			push_warning("No mesh named '%s' inside %s" % [item.node, item.model])
			continue

		var source: MeshInstance3D = found
		var mesh: Mesh = source.mesh
		# The object carries the rotation and scale it had inside the pack. Keep
		# that so it stays the right way up, then fit it to our own box.
		var oriented_basis := _basis_from_root(source, opened[item.model])
		var oriented: AABB = Transform3D(oriented_basis, Vector3.ZERO) * mesh.get_aabb()
		var footprint: float = maxf(oriented.size.x, oriented.size.z)
		if footprint <= 0.0 or oriented.size.y <= 0.0:
			continue

		var fit := Vector3(item.width / footprint, item.height / oriented.size.y, item.width / footprint)
		var final_basis := oriented_basis.scaled(fit)
		var final_aabb: AABB = Transform3D(final_basis, Vector3.ZERO) * mesh.get_aabb()
		_visuals[item.name] = {
			"mesh": mesh,
			# centre the model on the body's origin, which is where the box is
			"transform": Transform3D(final_basis, -final_aabb.get_center()),
		}

	for root in opened.values():
		(root as Node).free()


## An object inside a glTF file sits under a chain of parents. Multiply their
## rotations and scales together to get how it is really oriented.
func _basis_from_root(node: Node3D, root: Node) -> Basis:
	var b := Basis.IDENTITY
	var walker: Node = node
	while walker != null and walker != root:
		if walker is Node3D:
			b = (walker as Node3D).transform.basis * b
		walker = walker.get_parent()
	return b


## Put an item's look onto a MeshInstance3D — the real model if it has one, a
## plain coloured shape if it does not. Used for the hanging preview and for the
## dropped piece, so the two can never disagree.
func _apply_visual(target: MeshInstance3D, item: Dictionary) -> void:
	if _visuals.has(item.name):
		var v: Dictionary = _visuals[item.name]
		target.mesh = v.mesh
		target.transform = v.transform
		target.material_override = null
	else:
		target.mesh = _primitive_mesh(item)
		target.transform = Transform3D.IDENTITY
		target.material_override = _make_material(item.color)


## Fallback look, used when an item has no model or the model could not be found.
func _primitive_mesh(item: Dictionary) -> Mesh:
	if item.shape == "cylinder":
		var cyl := CylinderMesh.new()
		cyl.top_radius = item.width * 0.5
		cyl.bottom_radius = item.width * 0.5
		cyl.height = item.height
		return cyl
	var box := BoxMesh.new()
	box.size = Vector3(item.width, item.height, item.width)
	return box


## The physics shape. This is what the game actually plays on, and it does not
## depend on the model at all.
func _make_shape(item: Dictionary) -> Shape3D:
	if item.shape == "cylinder":
		var cyl := CylinderShape3D.new()
		cyl.radius = item.width * 0.5
		cyl.height = item.height
		return cyl
	var box := BoxShape3D.new()
	box.size = Vector3(item.width, item.height, item.width)
	return box


func _make_material(color: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.75
	return mat
