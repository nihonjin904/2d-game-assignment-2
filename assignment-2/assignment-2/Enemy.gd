# Enemy.gd 腳本

extends Area2D

@export var speed = 100.0
@export var loot_scene: PackedScene # Assign Loot.tscn here or load dynamically

var speed_modifier = 1.0

# 🌟 新增：獲取 AnimatedSprite2D 節點的引用
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D 

func _ready():
	add_to_group("enemy")
	
	# 錯誤檢查：如果 AnimatedSprite2D 找不到，則發出警告
	if !animated_sprite:
		print("警告: 敵人的 AnimatedSprite2D 節點未找到，動畫和面朝邏輯將失效。")
	else:
		# 🌟 確保敵人在準備好時開始播放動畫
		animated_sprite.play("walk") 
	
	# Connect signals via code to ensure they work even if user forgets in editor
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)
	
	# Load loot scene dynamically if not assigned
	if not loot_scene:
		loot_scene = load("res://Loot.tscn")

func _physics_process(delta):
	var player = get_tree().get_first_node_in_group("player")
	if player:
		# 1. 計算朝向玩家的方向向量
		var direction = global_position.direction_to(player.global_position)
		
		# 2. 🌟 更新敵人的面朝方向
		_update_facing_direction(direction)
		
		# 3. 執行移動
		position += direction * speed * speed_modifier * delta


# 🌟 新增函數：根據移動方向更新敵人的面朝方向
func _update_facing_direction(move_direction: Vector2):
	# 如果 animated_sprite 為 null，則退出
	if !animated_sprite:
		return
		
	# 只需要檢查水平移動 (X 軸)
	if move_direction.x < 0:
		# 向左移動 (X < 0)，將精靈水平翻轉
		animated_sprite.flip_h = true
	elif move_direction.x > 0:
		# 向右移動 (X > 0)，取消水平翻轉
		animated_sprite.flip_h = false
		
# 🌟 (可選) 簡單的動畫播放控制，確保敵人在移動時一直播放 'walk'
func _play_animation(animation_name: String):
	if animated_sprite and animated_sprite.is_playing() == false:
		animated_sprite.play(animation_name)


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
			
		queue_free() # Destroy enemy

func _on_body_entered(body):
	# Player detection (Player is CharacterBody2D)
	if body.is_in_group("player"):
		# Deal damage to player
		if body.has_method("take_damage"):
			body.take_damage()
		else:
			# Fallback if method missing (shouldn't happen)
			get_tree().reload_current_scene()
