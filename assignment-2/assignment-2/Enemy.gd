extends Area2D

@export var speed = 100.0
@export var loot_scene: PackedScene # Assign Loot.tscn here or load dynamically

var speed_modifier = 1.0
var max_hp = 1
var current_hp = 1
var xp_value = 10
var is_boss = false

func _ready():
	add_to_group("enemy")
	# Connect signals via code to ensure they work even if user forgets in editor
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)
	
	current_hp = max_hp
	
	# Load loot scene dynamically if not assigned
	if not loot_scene:
		loot_scene = load("res://Loot.tscn")

func init_boss(level_xp_req):
	is_boss = true
	scale = Vector2(5, 5)
	max_hp = 5 * 5 # 5x normal HP (assuming normal is 1, maybe should be higher?)
	# Let's say normal enemy HP is 1. Boss HP 25 is fine.
	current_hp = max_hp
	speed *= 0.8
	xp_value = int(level_xp_req * 0.5)
	# modulate = Color(1, 0.2, 0.2) # Removed red tint as requested
	
	if has_node("AnimatedSprite2D"):
		$AnimatedSprite2D.play("Enemy_Frames.tres")


func _physics_process(delta):
	var player = get_tree().get_first_node_in_group("player")
	if player:
		var direction = global_position.direction_to(player.global_position)
		position += direction * speed * speed_modifier * delta
		
		# Flip sprite based on direction
		if has_node("AnimatedSprite2D"):
			if direction.x < 0:
				$AnimatedSprite2D.flip_h = true
			elif direction.x > 0:
				$AnimatedSprite2D.flip_h = false



func _on_area_entered(area):
	# Bullet detection is handled in Bullet.gd usually, but can be here too.
	# If Bullet is an Area2D and in group "bullet"
	if area.is_in_group("bullet"):
		area.queue_free() # Destroy bullet
		take_damage(1)

func take_damage(amount):
	current_hp -= amount
	if current_hp <= 0:
		die()

func die():
	# Notify Main about the kill
	var main = get_tree().root.get_node("Main")
	if main and main.has_method("add_kill"):
		main.add_kill()
	
	# Drop Loot
	if loot_scene:
		var loot = loot_scene.instantiate()
		loot.global_position = global_position
		loot.xp_amount = xp_value
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
