extends Area2D

@onready var lightning_line = $LightningLine

var radius = 200.0
var lightning_points = 30
var lightning_jitter = 10.0

func _ready():
	# Ensure we have a Line2D child
	if not has_node("LightningLine"):
		lightning_line = Line2D.new()
		lightning_line.name = "LightningLine"
		lightning_line.width = 2.0
		lightning_line.default_color = Color(0.6, 0.9, 1.0) # Light blue lightning
		add_child(lightning_line)
	
	# Set process to true for animation
	set_process(true)

func _draw():
	# Draw pale blue circle
	draw_circle(Vector2.ZERO, radius, Color(0.5, 0.8, 1.0, 0.2))
	# Draw border
	draw_arc(Vector2.ZERO, radius, 0, TAU, 64, Color(0.5, 0.8, 1.0, 0.5), 2.0)

func _process(delta):
	if not visible:
		return
		
	update_lightning()
	queue_redraw() # Redraw to keep circle visible if needed, though usually _draw is static-ish

func update_lightning():
	if not lightning_line:
		return
		
	var points = []
	for i in range(lightning_points + 1):
		var angle = (float(i) / lightning_points) * TAU
		var base_pos = Vector2(cos(angle), sin(angle)) * radius
		
		# Add jitter for lightning effect
		var jitter = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * lightning_jitter
		points.append(base_pos + jitter)
	
	# Close the loop perfectly
	points[points.size() - 1] = points[0]
	
	lightning_line.points = PackedVector2Array(points)
