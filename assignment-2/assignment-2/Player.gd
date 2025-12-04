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
	
	# Connect SlowField signals if node exists (it will be added in scene)
	if has_node("SlowField"):
		# Enemy is an Area2D, so we need area_entered, not body_entered
		$SlowField.area_entered.connect(_on_slow_field_area_entered)
		$SlowField.area_exited.connect(_on_slow_field_area_exited)
		$SlowField.monitoring = false # Disabled by default
		$SlowField/CollisionShape2D.disabled = true
		$SlowField.visible = false

func _on_slow_field_area_entered(area):
	if area.is_in_group("enemy"):
		area.speed_modifier = 0.5 # Slow down by 50%
		print("Enemy entered slow field")

func _on_slow_field_area_exited(area):
	if area.is_in_group("enemy"):
		area.speed_modifier = 1.0 # Restore speed
		print("Enemy exited slow field")



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
		var mouse_pos = get_global_mouse_position()
		var base_direction = global_position.direction_to(mouse_pos)
		
		var angles = [0.0]
		if skill_triple_shot:
			angles = [-PI/4, 0.0, PI/4] # -45, 0, +45 degrees
			
		for angle in angles:
			var bullet = bullet_scene.instantiate()
			get_parent().add_child(bullet)
			bullet.global_position = global_position
			bullet.scale *= bullet_scale_multiplier
			bullet.speed *= bullet_speed_multiplier
			
			var final_direction = base_direction.rotated(angle)

			bullet.direction = final_direction
			bullet.rotation = final_direction.angle()



func take_damage():
	if is_invincible:
		return
		
	if skill_armor and is_armor_ready:
		deactivate_armor()
		print("Armor blocked damage (fallback)!")
		start_invincibility()
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
	# Notify Main about level up
	var main = get_tree().root.get_node("Main")
	if main and main.has_method("on_player_level_up"):
		main.on_player_level_up(level)

# Skills
var skill_triple_shot = false
var skill_armor = false
var skill_slow_field = false

var bullet_scale_multiplier = 1.0
var bullet_speed_multiplier = 1.0

var is_armor_ready = false
var armor_cooldown_timer = 0.0
var armor_cooldown_duration = 30.0

func activate_skill(skill_name):
	if skill_name == "attack":
		skill_triple_shot = true
		print("Skill Activated: Triple Shot")
	elif skill_name == "defense":
		skill_armor = true
		activate_armor()
		print("Skill Activated: Passive Armor")
	elif skill_name == "control":
		skill_slow_field = true
		$SlowField.monitoring = true
		$SlowField/CollisionShape2D.disabled = false
		$SlowField.visible = true
		print("Skill Activated: Slow Field")
	elif skill_name == "fire_rate":
		shoot_interval /= 1.25
		print("Skill Activated: Fire Rate Up (Interval: ", shoot_interval, ")")
	elif skill_name == "bullet_size":
		bullet_scale_multiplier = 1.25
		print("Skill Activated: Big Bullets")
	elif skill_name == "move_speed":
		speed *= 1.5
		print("Skill Activated: Move Speed Up (Speed: ", speed, ")")
	elif skill_name == "small_player":
		scale *= 0.5
		print("Skill Activated: Tiny Player")
	elif skill_name == "bullet_speed":
		bullet_speed_multiplier *= 1.1
		print("Skill Activated: Bullet Speed Up")
	elif skill_name == "magnet":
		if has_node("MagnetField"):
			$MagnetField.monitoring = true
			$MagnetField/CollisionShape2D.disabled = false
			if not $MagnetField.area_entered.is_connected(_on_magnet_field_area_entered):
				$MagnetField.area_entered.connect(_on_magnet_field_area_entered)
		print("Skill Activated: Magnet")

func _on_magnet_field_area_entered(area):
	if area.is_in_group("loot") and area.has_method("attract_to"):
		area.attract_to(self)




func activate_armor():
	is_armor_ready = true
	if has_node("ArmorShield"):
		$ArmorShield.visible = true
		$ArmorShield.monitoring = true
		$ArmorShield/CollisionShape2D.disabled = false
		# Connect signal if not already connected
		if not $ArmorShield.area_entered.is_connected(_on_armor_shield_area_entered):
			$ArmorShield.area_entered.connect(_on_armor_shield_area_entered)

func deactivate_armor():
	is_armor_ready = false
	armor_cooldown_timer = armor_cooldown_duration
	if has_node("ArmorShield"):
		$ArmorShield.visible = false
		$ArmorShield.monitoring = false
		$ArmorShield/CollisionShape2D.disabled = true

func _on_armor_shield_area_entered(area):
	if is_armor_ready and area.is_in_group("enemy"):
		print("Armor destroyed enemy!")
		area.queue_free() # Destroy enemy
		
		# Notify Main about kill (optional, but good for score)
		var main = get_tree().root.get_node("Main")
		if main and main.has_method("add_kill"):
			main.add_kill()
			
		deactivate_armor()

func _process(delta):
	# Armor Cooldown
	if skill_armor and not is_armor_ready:
		armor_cooldown_timer -= delta
		
		# Debug print every 1 second (approx)
		if int(armor_cooldown_timer) != int(armor_cooldown_timer + delta):
			print("Armor Cooldown: ", int(armor_cooldown_timer))
			
		if armor_cooldown_timer <= 0:
			activate_armor()
			print("Armor Regenerated!")
