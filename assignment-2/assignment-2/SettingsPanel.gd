extends PanelContainer

signal back_pressed

@onready var bgm_slider = $VBoxContainer/BGMContainer/BGMSlider
@onready var sfx_slider = $VBoxContainer/SFXContainer/SFXSlider
@onready var back_button = $VBoxContainer/BackButton

func _ready():
	# Connect signals
	bgm_slider.value_changed.connect(_on_bgm_volume_changed)
	sfx_slider.value_changed.connect(_on_sfx_volume_changed)
	back_button.pressed.connect(_on_back_pressed)
	
	# Initialize sliders
	bgm_slider.value = Global.get_bus_volume("Music")
	sfx_slider.value = Global.get_bus_volume("SFX")

func _on_bgm_volume_changed(value):
	Global.set_bus_volume("Music", value)

func _on_sfx_volume_changed(value):
	Global.set_bus_volume("SFX", value)

func _on_back_pressed():
	emit_signal("back_pressed")
	hide()
