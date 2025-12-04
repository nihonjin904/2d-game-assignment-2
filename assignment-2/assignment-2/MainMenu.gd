extends Control

@onready var settings_panel = $SettingsPanel
@onready var main_container = $CenterContainer

var gallery_panel

func _ready():
	$CenterContainer/VBoxContainer/StartButton.pressed.connect(_on_start_pressed)
	$CenterContainer/VBoxContainer/SettingsButton.pressed.connect(_on_settings_pressed)
	$CenterContainer/VBoxContainer/ExitButton.pressed.connect(_on_exit_pressed)
	$GalleryButton.pressed.connect(_on_gallery_pressed)
	settings_panel.back_pressed.connect(_on_settings_back)
	
	# Load Gallery Panel
	var gallery_scene = load("res://GalleryPanel.tscn")
	if gallery_scene:
		gallery_panel = gallery_scene.instantiate()
		gallery_panel.visible = false
		gallery_panel.back_pressed.connect(_on_gallery_back)
		add_child(gallery_panel)

func _on_start_pressed():
	get_tree().change_scene_to_file("res://Main.tscn")

func _on_settings_pressed():
	main_container.hide()
	$GalleryButton.hide()
	settings_panel.show()

func _on_gallery_pressed():
	main_container.hide()
	$GalleryButton.hide()
	gallery_panel.update_gallery() # Refresh status
	gallery_panel.show()

func _on_exit_pressed():
	get_tree().quit()

func _on_settings_back():
	settings_panel.hide()
	main_container.show()
	$GalleryButton.show()

func _on_gallery_back():
	gallery_panel.hide()
	main_container.show()
	$GalleryButton.show()

