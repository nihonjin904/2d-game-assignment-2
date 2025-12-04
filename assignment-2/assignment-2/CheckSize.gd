@tool
extends EditorScript

func _run():
	var texture = load("res://Background.png")
	if texture:
		print("Texture Size: ", texture.get_size())
	else:
		print("Failed to load texture")
