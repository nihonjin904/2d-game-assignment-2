extends Area2D

@export var speed = 400.0
var direction = Vector2.RIGHT

# 🌟 新增對 AudioStreamPlayer2D 節點的引用
@onready var shoot_sound = $Shoot_Sound

func _ready():
	add_to_group("bullet")
	
	# Force set SFX bus
	if has_node("Shoot_Sound"):
		$Shoot_Sound.bus = "SFX"
		$Shoot_Sound.play()

		
	# 使用計時器進行自動清理（5秒後銷毀子彈）
	get_tree().create_timer(5.0).timeout.connect(queue_free)
	
func _physics_process(delta):
	position += direction * speed * delta

# 這是由 Player.gd 呼叫來設定方向的函數
func set_direction(new_direction: Vector2):
	direction = new_direction

# Collision with Enemy is handled in Enemy.gd to keep logic simple there 
# (Enemy checks if it got hit).
