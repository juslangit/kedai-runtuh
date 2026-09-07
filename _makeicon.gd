extends Node
## Draws the app icon rather than shipping a hand-made file, so it can be
## regenerated at any size. A wobbling stack of dishes, readable at 48 pixels.
## Android wants a launcher icon at 192 and an adaptive foreground at 432; the
## project itself uses 512. Same drawing, three sizes.
const OUTPUTS := {
	"res://icon.png": 512,
	"res://icon_192.png": 192,
	"res://icon_432.png": 432,
}

var SIZE := 512

func _ready() -> void:
	for path in OUTPUTS:
		SIZE = OUTPUTS[path]
		_draw_one(path)
	get_tree().quit()


func _draw_one(path: String) -> void:
	var img := Image.create(SIZE, SIZE, false, Image.FORMAT_RGBA8)
	img.fill(Color("c0553c"))                      # warm kedai red

	# a lighter panel so the stack reads against the red
	_rect(img, 0.10, 0.10, 0.80, 0.80, 0.10, Color("d9694d"))

	# the table
	_rect(img, 0.14, 0.72, 0.72, 0.07, 0.02, Color("5a3a26"))

	# the stack, each piece nudged sideways so it looks about to go
	_rect(img, 0.24, 0.60, 0.52, 0.12, 0.05, Color("f4f1ea"))   # plate
	_rect(img, 0.30, 0.44, 0.44, 0.16, 0.04, Color("b5563c"))   # box
	_rect(img, 0.26, 0.34, 0.40, 0.10, 0.04, Color("f3e2b0"))   # egg
	_rect(img, 0.36, 0.18, 0.30, 0.16, 0.05, Color("e3d3b4"))   # cup
	_rect(img, 0.34, 0.14, 0.34, 0.05, 0.02, Color("dba441"))   # a lid, tilting

	img.save_png(path)
	print("wrote %s at %dx%d" % [path, SIZE, SIZE])


## A rounded rectangle, in fractions of the icon so the size can change freely.
func _rect(img: Image, fx: float, fy: float, fw: float, fh: float, fr: float, c: Color) -> void:
	var x0 := int(fx * SIZE); var y0 := int(fy * SIZE)
	var w := int(fw * SIZE);  var h := int(fh * SIZE)
	var r := minf(fr * SIZE, minf(w, h) * 0.5)
	for y in range(y0, y0 + h):
		for x in range(x0, x0 + w):
			if x < 0 or y < 0 or x >= SIZE or y >= SIZE:
				continue
			# only the corners need the distance test
			var cx: float = clampf(float(x), x0 + r, x0 + w - r)
			var cy: float = clampf(float(y), y0 + r, y0 + h - r)
			if Vector2(x - cx, y - cy).length() <= r:
				img.set_pixel(x, y, c)
