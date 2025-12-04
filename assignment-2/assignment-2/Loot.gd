extends Area2D

@export var xp_amount = 10

var target_body: Node2D = null
var move_speed = 400.0

func _ready():
	add_to_group("loot")
	body_entered.connect(_on_body_entered)

func _physics_process(delta):
	if target_body:
		var direction = global_position.direction_to(target_body.global_position)
		position += direction * move_speed * delta

func attract_to(body):
	target_body = body

func _on_body_entered(body):
	if body.is_in_group("player"):
		if body.has_method("gain_experience"):
			body.gain_experience(xp_amount)
		queue_free()
