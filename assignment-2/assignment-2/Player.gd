extends CharacterBody2D

@export var speed = 200.0
@export var bullet_scene: PackedScene
@export var shoot_interval = 0.5
@export var max_lives = 3

var current_lives = 3
var shoot_timer = 0.0
var is_invincible = false
var invincibility_timer = 0.0
var blink_timer = 0.0

func _ready():
	current_lives = max_lives

func _physics_process(delta):
	# Movement - Explicitly checking keys to ensure WASD works without Input Map setup
	var direction = Vector2.ZERO
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		direction.y -= 1
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		direction.y += 1
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		direction.x -= 1
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		direction.x += 1
	
	if direction.length() > 0:
		direction = direction.normalized()
	
	velocity = direction * speed
	move_and_slide()

	# Shooting
	shoot_timer += delta
	if shoot_timer >= shoot_interval:
		shoot_at_mouse()
		shoot_timer = 0.0

	# Invincibility & Blinking
	if is_invincible:
		invincibility_timer -= delta
		if invincibility_timer <= 0:
			is_invincible = false
			$ColorRect.visible = true # Ensure visible when invincibility ends
		else:
			# Blink effect
			blink_timer -= delta
			if blink_timer <= 0:
				$ColorRect.visible = not $ColorRect.visible
				blink_timer = 0.1 # Blink every 0.1 seconds

func shoot_at_mouse():
	if bullet_scene:
		var bullet = bullet_scene.instantiate()
		get_parent().add_child(bullet)
		bullet.global_position = global_position
		
		# Aim at mouse
		var mouse_pos = get_global_mouse_position()
		bullet.direction = global_position.direction_to(mouse_pos)
		bullet.look_at(mouse_pos)

func take_damage():
	if is_invincible:
		return
		
	current_lives -= 1
	print("Player hit! Lives left: ", current_lives)
	
	if current_lives <= 0:
		# Call game_over on Main node (parent)
		if get_parent().has_method("game_over"):
			get_parent().game_over()
		else:
			get_tree().reload_current_scene()
	else:
		start_invincibility()

func start_invincibility():
	is_invincible = true
	invincibility_timer = 3.0
	blink_timer = 0.0

# XP System
var experience = 0
var max_experience = 100
var level = 1

func gain_experience(amount):
	experience += amount
	print("XP Gained: ", amount, " Total: ", experience, "/", max_experience)
	if experience >= max_experience:
		level_up()

func level_up():
	experience -= max_experience
	level += 1
	max_experience = int(max_experience * 1.2) # Increase required XP by 20%
	print("Level Up! New Level: ", level)
	# Optional: Heal on level up? Or just increase stats?
	# For now just level up.
