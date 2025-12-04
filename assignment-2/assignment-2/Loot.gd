extends Area2D

@export var xp_amount = 10

func _ready():
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if body.is_in_group("player"):
		if body.has_method("gain_experience"):
			body.gain_experience(xp_amount)
		queue_free()
