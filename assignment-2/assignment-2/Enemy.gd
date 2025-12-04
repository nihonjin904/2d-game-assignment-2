extends Area2D

@export var speed = 100.0
@export var loot_scene: PackedScene # Assign Loot.tscn here or load dynamically

var speed_modifier = 1.0

func _ready():
	add_to_group("enemy")
	# Connect signals via code to ensure they work even if user forgets in editor
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)
	
	# Load loot scene dynamically if not assigned
	if not loot_scene:
		loot_scene = load("res://Loot.tscn")

func _physics_process(delta):
	var player = get_tree().get_first_node_in_group("player")
	if player:
		var direction = global_position.direction_to(player.global_position)
		position += direction * speed * speed_modifier * delta


func _on_area_entered(area):
	# Bullet detection is handled in Bullet.gd usually, but can be here too.
	# If Bullet is an Area2D and in group "bullet"
	if area.is_in_group("bullet"):
		area.queue_free() # Destroy bullet
		
		# Notify Main about the kill
		var main = get_tree().root.get_node("Main")
		if main and main.has_method("add_kill"):
			main.add_kill()
		
		# Drop Loot (50% chance)
		if randf() < 0.5 and loot_scene:
			var loot = loot_scene.instantiate()
			loot.global_position = global_position
			get_parent().call_deferred("add_child", loot)
			
		queue_free()      # Destroy enemy

func _on_body_entered(body):
	# Player detection (Player is CharacterBody2D)
	if body.is_in_group("player"):
		# Deal damage to player
		if body.has_method("take_damage"):
			body.take_damage()
		else:
			# Fallback if method missing (shouldn't happen)
			get_tree().reload_current_scene()
