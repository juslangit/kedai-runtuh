extends Node3D
## The title screen. The mamak stall behind it is the same set the game uses,
## so the menu and the game look like the same place.

@onready var ui: Control = $UI/Root
@onready var settings_panel: Control = $UI/SettingsPanel
@onready var best_label: Label = $UI/Root/Layout/Best


func _ready() -> void:
	ui.theme = UITheme.get_theme()
	$UI/Root/Layout/Play.pressed.connect(_on_play)
	$UI/Root/Layout/Settings.pressed.connect(settings_panel.open)
	$UI/Root/Layout/Quit.pressed.connect(_on_quit)
	# the best score can change in settings, so refresh it on the way back
	settings_panel.closed.connect(_refresh_best)

	Audio.wire_buttons(ui)
	Audio.start_music()

	_refresh_best()
	$UI/Root/Layout/Play.grab_focus()


func _on_play() -> void:
	get_tree().change_scene_to_file("res://scenes/main.tscn")


func _on_quit() -> void:
	get_tree().quit()


func _refresh_best() -> void:
	best_label.text = "BEST  %d" % SaveData.high_score
