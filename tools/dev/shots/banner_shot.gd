extends Node
## Renders the two stills the store banner is built from.
##
## The ordinary press shots stop at score 9, and a score is not a piece count -
## a perfect landing is worth two, and the autoplay lands dead centre nearly
## every time, so score 9 is only four or five dishes. A banner wants a tower
## that actually looks tall, so this counts the pieces themselves and shoots at
## TARGET_PIECES. It is a target rather than "as tall as possible" on purpose:
## past about a dozen dishes the camera has climbed so far that the tower runs
## off the bottom of the frame and the picture is mostly empty sky. A tower that
## fills the frame sells the game better than a taller one that does not fit.
##
## It also hides the PERFECT toast before shooting, so the word does not end up
## baked into the backdrop.
##
## NOTE: run this WINDOWED, not --headless. Headless uses a dummy renderer where
## RenderingServer.frame_post_draw never fires, so _shot() waits forever and the
## whole thing hangs without printing anything.
##
##   /Applications/Godot.app/Contents/MacOS/Godot --headless --path . \
##       res://tools/dev/shots/banner_shot.tscn
##
## Writes press/08_banner_tower.png (the tower, for the phone mock) and
## press/09_banner_plate.png (the same frame with the HUD off, for the backdrop).
const TARGET_PIECES := 10     ## a tower this tall still fits the frame
const ATTEMPTS := 6           ## how many runs to try before settling for less
const FRAME_BUDGET := 2400    ## give up on a run that goes nowhere
var OUT := ProjectSettings.globalize_path("res://press")
var _tallest := 0

func _ready() -> void:
	SaveData.high_score = 59
	for attempt in ATTEMPTS:
		var main = load("res://scenes/main.tscn").instantiate()
		add_child(main)
		await get_tree().process_frame
		var guard := 0
		while main.state != 2 and guard < FRAME_BUDGET:
			await get_tree().process_frame
			guard += 1
			if main.state != 0:
				continue
			var n: int = main.pieces.get_child_count()
			# Keep the best shot so far, so a run that never reaches the target
			# still leaves something usable behind.
			if n > _tallest and n <= TARGET_PIECES and main.preview.visible:
				_tallest = n
				await _settle(main)
				await _shot(main, "08_banner_tower", true)
				await _shot(main, "09_banner_plate", false)
				print("  shot at %d pieces, score %d" % [n, main.score])
				if n == TARGET_PIECES:
					print("done - reached the target of %d pieces" % TARGET_PIECES)
					get_tree().quit()
					return
			if absf(main.hook.position.x - _aim(main)) < 0.10:
				main._drop()
		print("attempt %d ended at %d pieces (score %d)" % [
			attempt + 1, main.pieces.get_child_count(), main.score])
		main.free()
	print("done - best tower shot was %d pieces (target was %d)" % [_tallest, TARGET_PIECES])
	get_tree().quit()

## Let the stack stop wobbling, and let the PERFECT toast fade, before shooting.
func _settle(main) -> void:
	main.get_node("UI/Hud/Perfect").hide()
	main.hint_label.hide()
	for i in 40:
		await get_tree().process_frame
	main.get_node("UI/Hud/Perfect").hide()

func _shot(main, name: String, hud: bool) -> void:
	main.get_node("UI/Hud").visible = hud
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	var err := img.save_png("%s/%s.png" % [OUT, name])
	print("saved %s  (%dx%d)  err=%d" % [name, img.get_width(), img.get_height(), err])

func _aim(main) -> float:
	var t := -999.0
	var x := 0.0
	for p in main.pieces.get_children():
		var b: AABB = main._world_box(p)
		if b.position.y + b.size.y > t:
			t = b.position.y + b.size.y
			x = b.position.x + b.size.x * 0.5
	return x
