extends Area2D

@export var speed = 400.0
var direction = Vector2.RIGHT

func _ready():
	add_to_group("bullet")
	# We can use VisibleOnScreenNotifier2D signal if node exists, 
	# or just simple distance check or timer for cleanup.
	# Let's assume user adds VisibleOnScreenNotifier2D as requested in instructions.
	# But to be safe, let's add a timer for auto-cleanup in code too.
	get_tree().create_timer(5.0).timeout.connect(queue_free)

func _physics_process(delta):
	position += direction * speed * delta

# Collision with Enemy is handled in Enemy.gd to keep logic simple there 
# (Enemy checks if it got hit).
