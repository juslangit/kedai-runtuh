extends Node3D
## The title screen. The kitchen behind it is the real 3D scene, not a picture,
## so the menu and the game look like the same place.

@onready var ui: Control = $UI/Root
@onready var sound_button: Button = $UI/Root/Layout/Sound
@onready var best_label: Label = $UI/Root/Layout/Best


func _ready() -> void:
	ui.theme = UITheme.get_theme()
	$UI/Root/Layout/Play.pressed.connect(_on_play)
	sound_button.pressed.connect(_on_sound)
	$UI/Root/Layout/Quit.pressed.connect(_on_quit)

	best_label.text = "TERBAIK  %d" % SaveData.high_score
	_refresh_sound()
	$UI/Root/Layout/Play.grab_focus()


func _on_play() -> void:
	get_tree().change_scene_to_file("res://scenes/main.tscn")


func _on_sound() -> void:
	SaveData.toggle_sound()
	_refresh_sound()


func _on_quit() -> void:
	get_tree().quit()


func _refresh_sound() -> void:
	sound_button.text = "BUNYI  %s" % ("ON" if SaveData.sound_on else "OFF")
