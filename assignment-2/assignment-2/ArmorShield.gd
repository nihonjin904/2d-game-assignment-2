extends Area2D

var radius = 30.0

func _draw():
	# Draw green circle outline
	draw_arc(Vector2.ZERO, radius, 0, TAU, 32, Color(0, 1, 0, 0.8), 3.0)
	# Draw faint fill
	draw_circle(Vector2.ZERO, radius, Color(0, 1, 0, 0.2))
