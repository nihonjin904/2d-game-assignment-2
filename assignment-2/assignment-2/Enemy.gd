# Enemy.gd 腳本 - 最終合併版本 (生命值/XP系統 + 面朝方向)

extends Area2D

@export var speed = 100.0
@export var loot_scene: PackedScene # Assign Loot.tscn here or load dynamically

var speed_modifier = 1.0
var max_hp = 1
var current_hp = 1
var xp_value = 10
var is_boss = false

# 🌟 您的 AnimatedSprite2D 引用
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D 

func _ready():
	add_to_group("enemy")
	
	# 錯誤檢查：如果 AnimatedSprite2D 找不到，則發出警告
	if !animated_sprite:
		print("警告: 敵人的 AnimatedSprite2D 節點未找到，動畫和面朝邏輯將失效。")
	else:
		# 🌟 確保敵人在準備好時開始播放動畫 (假設您的動畫名稱是 "walk")
		animated_sprite.play("walk") 
	
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
	max_hp = 5 * 5 
	current_hp = max_hp
	speed *= 0.8
	xp_value = int(level_xp_req * 0.5)
	modulate = Color(1, 0.2, 0.2) # Red tint

func _physics_process(delta):
	var player = get_tree().get_first_node_in_group("player")
	if player:
		# 1. 計算朝向玩家的方向向量
		var direction = global_position.direction_to(player.global_position)
		
		# 2. 🌟 您的面朝方向邏輯
		_update_facing_direction(direction)
		
		# 3. 執行移動
		position += direction * speed * speed_modifier * delta


# 🌟 您的面朝方向邏輯
func _update_facing_direction(move_direction: Vector2):
	if !animated_sprite:
		return
		
	# 只需要檢查水平移動 (X 軸)
	if move_direction.x < 0:
		animated_sprite.flip_h = true
	elif move_direction.x > 0:
		animated_sprite.flip_h = false
		
# 🌟 您的動畫播放邏輯
func _play_animation(animation_name: String):
	if animated_sprite and animated_sprite.is_playing() == false:
		animated_sprite.play(animation_name)


func _on_area_entered(area):
	if area.is_in_group("bullet"):
		area.queue_free() # Destroy bullet
		take_damage(1) # 朋友的生命值邏輯

func take_damage(amount):
	current_hp -= amount
	if current_hp <= 0:
		die()

func die():
	# Notify Main about the kill (朋友的邏輯)
	var main = get_tree().root.get_node("Main")
	if main and main.has_method("add_kill"):
		main.add_kill()
	
	# Drop Loot (朋友的邏輯 - 包含 XP 值)
	if loot_scene:
		var loot = loot_scene.instantiate()
		loot.global_position = global_position
		# 確保 Loot.gd 中有 xp_amount 屬性
		if loot.has_method("set_xp_amount"):
			loot.set_xp_amount(xp_value) 
		else:
			loot.xp_amount = xp_value 
			
		get_parent().call_deferred("add_child", loot)
		
	queue_free() 


func _on_body_entered(body):
	# Player detection (Player is CharacterBody2D)
	if body.is_in_group("player"):
		# Deal damage to player
		if body.has_method("take_damage"):
			body.take_damage()
		else:
			get_tree().reload_current_scene()
