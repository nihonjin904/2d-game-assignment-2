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
var skill_triple_shot = false
var skill_armor = false
var skill_slow_field = false

var bullet_scale_multiplier = 1.0
var bullet_speed_multiplier = 1.0

var is_armor_ready = false
var armor_cooldown_timer = 0.0
var armor_cooldown_duration = 30.0

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

# 🌟 使用 _process 處理不依賴物理運算的邏輯，例如冷卻時間
# 修正錯誤 1: 將參數改為 _delta，避免 Godot 警告
func _process(_delta):
	# Armor Cooldown
	if skill_armor and not is_armor_ready:
		armor_cooldown_timer -= _delta
		if armor_cooldown_timer <= 0:
			activate_armor()
			print("Armor Regenerated!")


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

			if bullet.has_method("set_direction"):
				bullet.set_direction(final_direction)
			else:
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
