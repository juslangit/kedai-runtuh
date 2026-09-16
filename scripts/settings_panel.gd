extends Control
## The settings screen, used by both the main menu and the pause menu.
##
## One scene instanced in two places rather than two copies, so a change to the
## wording or the options happens once.

## The attribution the model licences actually require. CC-BY means the author
## must be credited "wherever you share it", and a repo file is not where a
## player looks — so it belongs in the game.
const CREDITS := """[b]3D models[/b]
"Stylized Food & Cafe Props Pack" by Pollypipe
licensed under CC-BY-4.0

[b]Art[/b]
Mamak stall, buttons and logo made with OpenArt
Font: Lilita One by Juan Montoreano, SIL Open Font License

[b]Sound[/b]
Music: "Ramen" by HoliznaCC0
Effects: Kenney (Interface & Impact Sounds)
all public domain, CC0 1.0

[b]Built with[/b]
Godot Engine — godotengine.org"""

signal closed

@onready var _music: Button = $Center/Panel/Box/Music
@onready var _sfx: Button = $Center/Panel/Box/Sfx
@onready var _haptics: Button = $Center/Panel/Box/Haptics
@onready var _reset: Button = $Center/Panel/Box/Reset
@onready var _credits_view: Control = $CreditsView

## The reset button asks once before it does anything.
var _reset_armed := false


func _ready() -> void:
	# Must keep working while the tree is paused, or it would be dead when opened
	# from the pause menu.
	process_mode = Node.PROCESS_MODE_ALWAYS
	theme = UITheme.get_theme()
	$CreditsView/Center/Panel/Box/Body.text = CREDITS

	_music.pressed.connect(func():
		SaveData.set_music(not SaveData.music_on); _refresh())
	_sfx.pressed.connect(func():
		SaveData.set_sfx(not SaveData.sfx_on); _refresh())
	_haptics.pressed.connect(func():
		SaveData.set_haptics(not SaveData.haptics_on)
		if SaveData.haptics_on:
			Haptics.land()   # let them feel what they just turned on
		_refresh())
	_reset.pressed.connect(_on_reset)
	# hide the settings list behind the credits, or its panel edge shows through
	$Center/Panel/Box/Credits.pressed.connect(func():
		$Center.hide(); _credits_view.show())
	$CreditsView/Center/Panel/Box/Back.pressed.connect(func():
		_credits_view.hide(); $Center.show())
	$Center/Panel/Box/Back.pressed.connect(close)

	Audio.wire_buttons(self)
	hide()
	_credits_view.hide()


func open() -> void:
	_reset_armed = false
	_credits_view.hide()
	$Center.show()
	_refresh()
	show()
	_music.grab_focus()


func close() -> void:
	hide()
	closed.emit()


func _on_reset() -> void:
	if not _reset_armed:
		_reset_armed = true
		_refresh()
		return
	SaveData.reset_high_score()
	_reset_armed = false
	_refresh()


func _refresh() -> void:
	_music.text = "MUSIC   %s" % _on_off(SaveData.music_on)
	_sfx.text = "SOUND   %s" % _on_off(SaveData.sfx_on)
	_haptics.text = "VIBRATION   %s" % _on_off(SaveData.haptics_on)
	if _reset_armed:
		_reset.text = "TAP AGAIN TO ERASE"
	else:
		_reset.text = "ERASE BEST SCORE  (%d)" % SaveData.high_score


func _on_off(value: bool) -> String:
	return "ON" if value else "OFF"
