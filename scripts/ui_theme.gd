class_name UITheme
extends RefCounted
## The look of every menu and button in the game, built in one place.
##
## Change a colour or a size here and it changes everywhere. Nothing else in the
## project sets its own button colours.
##
## Buttons come in three kinds, chosen with `theme_type_variation` on the node:
##   (none)          — the ordinary cream button
##   "PrimaryButton" — the big red one you are meant to press
##   "IconButton"    — the small round one, used for pause

# The kedai palette. These are picked to sit with the food and the kitchen.
const CREAM        := Color("f6efe1")
const CREAM_DEEP   := Color("e6d7b8")
const BROWN        := Color("3a2a20")
const BROWN_SOFT   := Color("6b5340")
const RED          := Color("c0553c")
const RED_DARK     := Color("9c4230")
const GOLD         := Color("dba441")
const DIM          := Color(0.075, 0.055, 0.043, 0.82)

# --- swapping in bought UI artwork ----------------------------------------
#
# Right now every button and panel is DRAWN by Godot — rounded boxes, no image
# files. To use an art pack instead (the Cozy UI Pack, for example), put its PNGs
# in assets/ui/ and write the filenames in here. Anything left as "" keeps the
# drawn version, so the game always runs and you can swap one piece at a time.
#
#   margin — the 9-slice border, in pixels of the source PNG: how much of each
#            edge is frame that must NOT stretch when the button is resized.
#            Cozy UI's 64px pieces are usually 16 or 20. Too small and the corners
#            smear; too large and the middle never fills.
const SPRITES := {
	"button":         {"path": "", "margin": 16},
	"button_pressed": {"path": "", "margin": 16},
	"button_primary": {"path": "", "margin": 16},
	"panel":          {"path": "", "margin": 32},
}

static var _cached: Theme


## The shared theme. Built once, then reused.
static func get_theme() -> Theme:
	if _cached == null:
		_cached = _build()
	return _cached


static func _build() -> Theme:
	var t := Theme.new()

	# --- ordinary button: cream with a soft brown edge ---------------------
	_button_style(t, "Button", CREAM_DEEP, Color("c19a63"), BROWN, 46)

	# --- the main action: warm red ----------------------------------------
	t.set_type_variation("PrimaryButton", "Button")
	_button_style(t, "PrimaryButton", RED, RED_DARK, CREAM, 58)

	# --- settings rows: same look, smaller so a list of them fits -----------
	t.set_type_variation("SettingsButton", "Button")
	_button_style(t, "SettingsButton", CREAM_DEEP, Color("c19a63"), BROWN, 38, 22, 30)

	# --- small round icon button ------------------------------------------
	t.set_type_variation("IconButton", "Button")
	_button_style(t, "IconButton", CREAM_DEEP, Color("c19a63"), BROWN, 40, 40, 0)

	# --- labels ------------------------------------------------------------
	t.set_color("font_color", "Label", BROWN)
	t.set_font_size("font_size", "Label", 40)

	t.set_type_variation("Title", "Label")
	t.set_color("font_color", "Title", CREAM)
	t.set_color("font_outline_color", "Title", BROWN)
	t.set_constant("outline_size", "Title", 18)
	t.set_font_size("font_size", "Title", 104)

	t.set_type_variation("Subtitle", "Label")
	t.set_color("font_color", "Subtitle", CREAM)
	t.set_color("font_outline_color", "Subtitle", BROWN)
	t.set_constant("outline_size", "Subtitle", 10)
	t.set_font_size("font_size", "Subtitle", 34)

	# HUD text sits over the game, so it needs an outline to stay readable
	# whatever colour of food happens to be behind it.
	t.set_type_variation("HudKey", "Label")
	t.set_color("font_color", "HudKey", Color(1, 1, 1, 0.72))
	t.set_color("font_outline_color", "HudKey", Color(0.08, 0.05, 0.04, 0.85))
	t.set_constant("outline_size", "HudKey", 10)
	t.set_font_size("font_size", "HudKey", 30)

	t.set_type_variation("HudValue", "Label")
	t.set_color("font_color", "HudValue", Color(1, 1, 1, 0.98))
	t.set_color("font_outline_color", "HudValue", Color(0.08, 0.05, 0.04, 0.9))
	t.set_constant("outline_size", "HudValue", 12)
	t.set_font_size("font_size", "HudValue", 64)

	t.set_type_variation("HudValueSmall", "Label")
	t.set_color("font_color", "HudValueSmall", Color(1, 1, 1, 0.9))
	t.set_color("font_outline_color", "HudValueSmall", Color(0.08, 0.05, 0.04, 0.9))
	t.set_constant("outline_size", "HudValueSmall", 10)
	t.set_font_size("font_size", "HudValueSmall", 42)

	t.set_type_variation("PanelTitle", "Label")
	t.set_color("font_color", "PanelTitle", BROWN)
	t.set_font_size("font_size", "PanelTitle", 68)

	t.set_type_variation("Celebrate", "Label")
	t.set_color("font_color", "Celebrate", Color("b07d1e"))
	t.set_font_size("font_size", "Celebrate", 36)

	t.set_color("default_color", "RichTextLabel", BROWN)
	t.set_font_size("normal_font_size", "RichTextLabel", 27)
	t.set_font_size("bold_font_size", "RichTextLabel", 29)

	t.set_type_variation("Fine", "Label")
	t.set_color("font_color", "Fine", BROWN_SOFT)
	t.set_font_size("font_size", "Fine", 26)

	t.set_type_variation("PanelScoreKey", "Label")
	t.set_color("font_color", "PanelScoreKey", BROWN_SOFT)
	t.set_font_size("font_size", "PanelScoreKey", 30)

	t.set_type_variation("PanelScoreValue", "Label")
	t.set_color("font_color", "PanelScoreValue", BROWN)
	t.set_font_size("font_size", "PanelScoreValue", 76)

	# --- panels ------------------------------------------------------------
	var panel := StyleBoxFlat.new()
	panel.bg_color = Color("fbf6ea")
	panel.set_corner_radius_all(36)
	panel.border_width_left = 6
	panel.border_width_right = 6
	panel.border_width_top = 6
	panel.border_width_bottom = 6
	panel.border_color = CREAM_DEEP
	panel.set_content_margin_all(44)
	panel.shadow_color = Color(0, 0, 0, 0.35)
	panel.shadow_size = 24
	t.set_stylebox("panel", "PanelContainer", panel)

	_apply_sprites(t)
	return t


## Replace the drawn boxes with artwork, wherever a path has been filled in above.
## Padding is copied from the drawn version it replaces, so buttons keep the same
## size and the layout does not shift when the art goes in.
static func _apply_sprites(t: Theme) -> void:
	var swaps := [
		["button", "Button", ["normal", "hover", "focus"]],
		["button_pressed", "Button", ["pressed"]],
		["button_primary", "PrimaryButton", ["normal", "hover", "focus"]],
		["panel", "PanelContainer", ["panel"]],
	]
	for swap in swaps:
		var key: String = swap[0]
		var type: String = swap[1]
		var slots: Array = swap[2]
		var existing := t.get_stylebox(slots[0], type)
		var box := _sprite(key, existing)
		if box == null:
			continue
		for slot in slots:
			t.set_stylebox(slot, type, box)


## One 9-sliced texture box, or null if no artwork was supplied for it.
static func _sprite(key: String, copy_padding_from: StyleBox) -> StyleBoxTexture:
	var entry: Dictionary = SPRITES.get(key, {})
	var path: String = str(entry.get("path", ""))
	if path == "" or not ResourceLoader.exists(path):
		return null
	var tex: Texture2D = load(path)
	if tex == null:
		push_warning("UI sprite could not be loaded: %s" % path)
		return null

	var box := StyleBoxTexture.new()
	box.texture = tex
	var m: float = float(entry.get("margin", 16))
	box.texture_margin_left = m
	box.texture_margin_right = m
	box.texture_margin_top = m
	box.texture_margin_bottom = m
	if copy_padding_from != null:
		box.content_margin_left = copy_padding_from.content_margin_left
		box.content_margin_right = copy_padding_from.content_margin_right
		box.content_margin_top = copy_padding_from.content_margin_top
		box.content_margin_bottom = copy_padding_from.content_margin_bottom
	return box


## One button style, in all four of its states.
static func _button_style(t: Theme, type: String, face: Color, edge: Color,
		text: Color, font_size: int, pad_v: int = 30, pad_h: int = 44) -> void:
	var base := StyleBoxFlat.new()
	base.bg_color = face
	base.set_corner_radius_all(28)
	base.border_width_bottom = 8
	base.border_color = edge
	base.content_margin_top = pad_v
	base.content_margin_bottom = pad_v
	base.content_margin_left = pad_h
	base.content_margin_right = pad_h

	var hover := base.duplicate() as StyleBoxFlat
	hover.bg_color = face.lightened(0.08)

	# Pressed drops the button onto its own shadow, which is what makes a tap
	# feel like it landed.
	var pressed := base.duplicate() as StyleBoxFlat
	pressed.bg_color = face.darkened(0.10)
	pressed.border_width_bottom = 0
	pressed.content_margin_top = pad_v + 8

	var focus := base.duplicate() as StyleBoxFlat
	focus.border_width_left = 4
	focus.border_width_right = 4
	focus.border_width_top = 4
	focus.border_width_bottom = 8
	focus.border_color = GOLD

	t.set_stylebox("normal", type, base)
	t.set_stylebox("hover", type, hover)
	t.set_stylebox("pressed", type, pressed)
	t.set_stylebox("focus", type, focus)
	t.set_stylebox("disabled", type, base)
	t.set_color("font_color", type, text)
	t.set_color("font_hover_color", type, text)
	t.set_color("font_pressed_color", type, text)
	t.set_color("font_focus_color", type, text)
	t.set_font_size("font_size", type, font_size)


## A pause glyph, drawn rather than shipped as an image file.
static func pause_icon(size: int = 48, color: Color = BROWN) -> ImageTexture:
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var bar := int(size * 0.20)
	var gap := int(size * 0.16)
	var top := int(size * 0.16)
	var bottom := size - top
	var left := int(size * 0.5 - gap * 0.5) - bar
	for y in range(top, bottom):
		for x in range(bar):
			img.set_pixel(left + x, y, color)
			img.set_pixel(left + bar + gap + x, y, color)
	return ImageTexture.create_from_image(img)
