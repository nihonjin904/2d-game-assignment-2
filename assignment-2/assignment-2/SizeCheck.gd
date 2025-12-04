extends Node

func _ready():
	var texture = load("res://Background.png")
	if texture:
		print("BACKGROUND_SIZE: ", texture.get_size())
	queue_free()
