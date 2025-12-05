# Player.gd 腳本 - 最終修正版（包含所有功能、滑鼠面向、地圖邊界和正確的閃爍）
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

# 🌟 獲取 AnimatedSprite2D 節點的引用
# 如果錯誤持續，請檢查 Player 場景下 AnimatedSprite2D 的名稱是否是 "AnimatedSprite2D"
@onready var animated_sprite = $AnimatedSprite2D 

# 技能相關變數
# 技能相關變數
var projectile_count = 1
var skill_fireball = false
var skill_dash = false
var skill_armor = false
var skill_slow_field = false

var bullet_scale_multiplier = 1.0
var bullet_speed_multiplier = 1.0

var is_armor_ready = false
var armor_cooldown_timer = 0.0
var armor_cooldown_duration = 30.0

# Dash Variables
var is_dashing = false
var dash_cooldown_timer = 0.0
var dash_duration_timer = 0.0
var dash_speed_multiplier = 3.0
var dash_cooldown = 3.0
var dash_duration = 0.2
var fireball_timer = 0.0
var fireball_cooldown = 3.0
var skill_lightning = false
var lightning_timer = 0.0
var lightning_cooldown = 5.0
var lightning_damage = 5
var lightning_jumps = 3
var lightning_range = 400.0

var pierce_count = 0
var hp_regen_timer = 0.0
var hp_regen_interval = 5.0
var has_regeneration = false

var experience = 0
var max_experience = 100
var level = 1


func _ready():
	current_lives = max_lives
	
	# Connect SlowField signals if node exists
	if has_node("SlowField"):
		$SlowField.area_entered.connect(_on_slow_field_area_entered)
		$SlowField.area_exited.connect(_on_slow_field_area_exited)
		$SlowField.monitoring = false
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

# 🌟 使用 _physics_process 處理所有移動和碰撞相關的邏輯
func _physics_process(delta):
	# Movement
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
		# 動畫：移動時播放 walk
		if animated_sprite:
			animated_sprite.play("walk") 
	else:
		# 動畫：停止時播放 idle
		if animated_sprite:
			animated_sprite.play("idle")
	
	velocity = direction * speed
	move_and_slide()
	
	# 面向滑鼠
	_update_aim_direction() 
	
	# 地圖邊界限制
	position.x = clamp(position.x, -5120, 5120)
	position.y = clamp(position.y, -5120, 5120)
	

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
			# 修正閃爍結束
			if animated_sprite:
				animated_sprite.visible = true 
		else:
			# Blink effect
			blink_timer -= delta
			if blink_timer <= 0:
				# 修正閃爍
				if animated_sprite:
					animated_sprite.visible = not animated_sprite.visible 
				blink_timer = 0.1 # Blink every 0.1 seconds


	# Dash Logic
	if is_dashing:
		dash_duration_timer -= delta
		if dash_duration_timer <= 0:
			is_dashing = false
			velocity = Vector2.ZERO # Stop dashing momentum
			print("Dash Ended")
			# End invincibility if it was only for dash (optional, but let's keep it simple)
			# We used start_invincibility() which sets it to 3.0s usually. 
			# For dash we might want shorter invincibility or just use the same flag.
			# Let's just let the invincibility timer run out naturally or reset it?
			# Actually, if we want dash to give I-frames ONLY during dash:
			is_invincible = false
			if animated_sprite:
				animated_sprite.visible = true
	else:
		if dash_cooldown_timer > 0:
			dash_cooldown_timer -= delta
			
		if skill_dash and Input.is_key_pressed(KEY_SPACE) and dash_cooldown_timer <= 0:
			start_dash()

# 🌟 使用 _process 處理不依賴物理運算的邏輯，例如冷卻時間
# 修正錯誤 1: 將參數改為 _delta，避免 Godot 警告
func _process(_delta):
	# Armor Cooldown
	if skill_armor and not is_armor_ready:
		armor_cooldown_timer -= _delta
		if armor_cooldown_timer <= 0:
			activate_armor()
			print("Armor Regenerated!")

	# HP Regeneration
	if has_regeneration and current_lives < max_lives:
		hp_regen_timer -= _delta
		if hp_regen_timer <= 0:
			current_lives += 1
			hp_regen_timer = hp_regen_interval
			print("HP Regenerated! Current HP: ", current_lives)
			
			# Update UI
			var main = get_tree().root.get_node("Main")
			if main and main.has_method("update_ui"):
				main.update_ui()
				
	# Fireball Auto-cast
	if skill_fireball:
		fireball_timer -= _delta
		if fireball_timer <= 0:
			shoot_fireball()
			fireball_timer = fireball_cooldown
			
	# Lightning Auto-cast
	if skill_lightning:
		lightning_timer -= _delta
		if lightning_timer <= 0:
			fire_lightning_chain()
			lightning_timer = lightning_cooldown


# 🌟 您的滑鼠面向邏輯 (修正錯誤 3: 確保函數存在)
func _update_aim_direction():
	if !animated_sprite:
		return
		
	var mouse_pos = get_global_mouse_position()
	var relative_x = mouse_pos.x - global_position.x
	
	if relative_x < 0:
		# 滑鼠在左邊
		animated_sprite.flip_h = true
	elif relative_x > 0:
		# 滑鼠在右邊
		animated_sprite.flip_h = false


func shoot_at_mouse():
	if bullet_scene:
		var mouse_pos = get_global_mouse_position()
		var base_direction = global_position.direction_to(mouse_pos)
		
		var angles = []
		if projectile_count == 1:
			angles = [0.0]
		else:
			# Spread angles evenly. e.g. 2 shots: -15, 15. 3 shots: -30, 0, 30.
			var total_spread = deg_to_rad(15 * (projectile_count - 1))
			var start_angle = -total_spread / 2.0
			var step = 0.0
			if projectile_count > 1:
				step = total_spread / (projectile_count - 1)
				
			for i in range(projectile_count):
				angles.append(start_angle + i * step)
			
		for angle in angles:
			var bullet = bullet_scene.instantiate()
			get_parent().add_child(bullet) 
			bullet.global_position = global_position
			bullet.scale *= bullet_scale_multiplier
			bullet.speed *= bullet_speed_multiplier
			if "pierce_count" in bullet:
				bullet.pierce_count = pierce_count
			
			var final_direction = base_direction.rotated(angle)

			if bullet.has_method("set_direction"):
				bullet.set_direction(final_direction)
			else:
				bullet.direction = final_direction
			
			bullet.rotation = final_direction.angle()

func shoot_fireball():
	if bullet_scene:
		var mouse_pos = get_global_mouse_position()
		var direction = global_position.direction_to(mouse_pos)
		
		var bullet = bullet_scene.instantiate()
		get_parent().add_child(bullet)
		bullet.global_position = global_position
		bullet.scale *= bullet_scale_multiplier * 2.0 # Bigger
		bullet.speed *= 0.8 # Slower
		bullet.is_explosive = true
		bullet.modulate = Color(1, 0.5, 0) # Orange
		
		if bullet.has_method("set_direction"):
			bullet.set_direction(direction)
		else:
			bullet.direction = direction
			
		bullet.rotation = direction.angle()
		print("Fireball Cast!")

func fire_lightning_chain():
	var enemies = get_tree().get_nodes_in_group("enemy")
	if enemies.size() == 0:
		return
		
	# Find nearest enemy
	var nearest_enemy = null
	var min_dist = lightning_range
	
	for enemy in enemies:
		var dist = global_position.distance_to(enemy.global_position)
		if dist < min_dist:
			min_dist = dist
			nearest_enemy = enemy
			
	if nearest_enemy:
		var current_target = nearest_enemy
		var targets_hit = []
		targets_hit.append(current_target)
		
		# Chain Logic
		for i in range(lightning_jumps):
			if current_target == null:
				break
				
			current_target.take_damage(lightning_damage)
			print("Lightning hit: ", current_target.name)
			
			# Find next target
			var next_target = null
			var next_min_dist = lightning_range
			
			for enemy in enemies:
				if enemy in targets_hit or enemy == current_target:
					continue
				var dist = current_target.global_position.distance_to(enemy.global_position)
				if dist < next_min_dist:
					next_min_dist = dist
					next_target = enemy
			
			# Visuals (Line2D)
			var line = Line2D.new()
			line.width = 5
			line.default_color = Color(0.5, 0.8, 1) # Light Blue
			if i == 0:
				line.add_point(global_position)
			else:
				# Ideally from previous target, but we only have current loop.
				# We can assume the previous hit was the source.
				# Let's simplify: Draw from Player -> Target 1 -> Target 2...
				pass
				
			# Better Visuals: Create a separate Line2D for each segment
			var segment = Line2D.new()
			segment.width = 3
			segment.default_color = Color(0.5, 0.8, 1)
			var start_pos = global_position
			if i > 0:
				start_pos = targets_hit[i-1].global_position
			
			segment.add_point(start_pos)
			segment.add_point(current_target.global_position)
			get_parent().add_child(segment)
			
			# Fade out line
			var tween = create_tween()
			tween.tween_property(segment, "modulate:a", 0.0, 0.3)
			tween.tween_callback(segment.queue_free)

			current_target = next_target
			if current_target:
				targets_hit.append(current_target)


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
	
	# 確保精靈在開始閃爍時是可見的
	if animated_sprite:
		animated_sprite.visible = true 

# XP System
func gain_experience(amount):
	experience += amount
	if experience >= max_experience:
		level_up()

func level_up():
	experience -= max_experience
	level += 1
	max_experience = int(max_experience * 1.2)
	print("Level Up! New Level: ", level)
	var main = get_tree().root.get_node("Main")
	if main and main.has_method("on_player_level_up"):
		main.on_player_level_up(level)


# Skills (保持不變)
func activate_skill(skill_name):
	if skill_name == "multishot":
		projectile_count = min(projectile_count + 1, 5)
		print("Skill Activated: Multi-shot (Count: ", projectile_count, ")")
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
		bullet_scale_multiplier *= 1.25
		print("Skill Activated: Big Bullets (Multiplier: ", bullet_scale_multiplier, ")")
	elif skill_name == "move_speed":
		speed *= 1.2 # Reduced from 1.5 to be more balanced for stacking
		print("Skill Activated: Move Speed Up (Speed: ", speed, ")")
	elif skill_name == "small_player":
		scale *= 0.8 # Reduced from 0.5 to be more balanced for stacking
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
	elif skill_name == "heal":
		current_lives = min(current_lives + 1, max_lives)
		print("Skill Activated: Heal")
	elif skill_name == "max_hp":
		max_lives += 1
		current_lives += 1
		print("Skill Activated: Max HP Up")
	elif skill_name == "piercing":
		pierce_count += 1
		print("Skill Activated: Piercing +1")
	elif skill_name == "regeneration":
		has_regeneration = true
		hp_regen_interval = max(1.0, hp_regen_interval * 0.8) # Reduce interval if picked multiple times
		print("Skill Activated: Regeneration")
	elif skill_name == "fireball":
		skill_fireball = true
		print("Skill Activated: Fireball")
	elif skill_name == "lightning_chain":
		skill_lightning = true
		print("Skill Activated: Lightning Chain")
	elif skill_name == "lightning_area":
		lightning_range *= 1.25
		print("Skill Activated: Lightning Range Up (Range: ", lightning_range, ")")

func start_dash():
	is_dashing = true
	dash_duration_timer = dash_duration
	dash_cooldown_timer = dash_cooldown
	
	# Dash towards mouse
	var mouse_pos = get_global_mouse_position()
	var dash_dir = global_position.direction_to(mouse_pos)
	velocity = dash_dir * speed * dash_speed_multiplier
	
	# I-frames
	is_invincible = true
	invincibility_timer = dash_duration # Only invincible during dash
	
	print("Dash Started!")

func _on_magnet_field_area_entered(area):
	if area.is_in_group("loot") and area.has_method("attract_to"):
		area.attract_to(self)


func activate_armor():
	is_armor_ready = true
	if has_node("ArmorShield"):
		$ArmorShield.visible = true
		$ArmorShield.monitoring = true
		$ArmorShield/CollisionShape2D.disabled = false
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
		area.queue_free()
		
		var main = get_tree().root.get_node("Main")
		if main and main.has_method("add_kill"):
			main.add_kill()
			
		deactivate_armor()
