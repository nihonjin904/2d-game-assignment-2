extends PanelContainer

signal back_pressed

@onready var cg1_texture = $VBoxContainer/GridContainer/CG1Container/TextureRect
@onready var cg1_label = $VBoxContainer/GridContainer/CG1Container/Label
@onready var cg2_texture = $VBoxContainer/GridContainer/CG2Container/TextureRect
@onready var cg2_label = $VBoxContainer/GridContainer/CG2Container/Label
@onready var back_button = $VBoxContainer/BackButton

var cg1_res = preload("res://Game_Over_CG.png")
var cg2_res = preload("res://Game_Over_CG_2.png")

func _ready():
	back_button.pressed.connect(_on_back_pressed)
	update_gallery()

func update_gallery():
	# CG1
	if Global.unlocked_cgs.get("cg1", false):
		cg1_texture.texture = cg1_res
		cg1_label.text = "Game Over 1"
	else:
		cg1_texture.texture = null # Or a lock icon
		cg1_label.text = "Locked"
		
	# CG2
	if Global.unlocked_cgs.get("cg2", false):
		cg2_texture.texture = cg2_res
		cg2_label.text = "Game Over 2"
	else:
		cg2_texture.texture = null
		cg2_label.text = "Locked"

func _on_back_pressed():
	emit_signal("back_pressed")
	hide()
