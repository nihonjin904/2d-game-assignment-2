extends Node2D

@export var enemy_scene: PackedScene

# UI Variables
var time_elapsed = 0.0
var kills = 0
var time_label: Label
var kill_label: Label
var xp_bar: ProgressBar
var level_label: Label

func _ready():
	# Create UI Layer
	var canvas_layer = CanvasLayer.new()
	add_child(canvas_layer)
	
	# Create Time Label
	time_label = Label.new()
	time_label.position = Vector2(500, 20) # Top Center-ish
	time_label.modulate = Color(1, 1, 1)
	time_label.add_theme_font_size_override("font_size", 24)
	canvas_layer.add_child(time_label)
	
	# Create Kill Label
	kill_label = Label.new()
	kill_label.position = Vector2(1000, 20) # Top Right
	kill_label.modulate = Color(1, 0, 0) # Red for kills
	kill_label.add_theme_font_size_override("font_size", 24)
	canvas_layer.add_child(kill_label)
	
	# Create Level Label (Bottom Left)
	level_label = Label.new()
	level_label.text = "Level: 1"
	level_label.add_theme_font_size_override("font_size", 20)
	level_label.position = Vector2(20, 610) # Bottom Left
	canvas_layer.add_child(level_label)
	
	# Create XP Bar (Bottom, Green, Right of Level Label)
	xp_bar = ProgressBar.new()
	xp_bar.position = Vector2(120, 615) # Right of Level Label
	xp_bar.size = Vector2(1152 - 140, 20) # Fill rest of width with padding
	xp_bar.show_percentage = false
	xp_bar.modulate = Color(0, 1, 0) # Green
	canvas_layer.add_child(xp_bar)

	# Create a timer for spawning enemies
	var timer = Timer.new()
	timer.wait_time = 1.0 # Spawn every 1 second
	timer.autostart = true
	timer.timeout.connect(_on_spawn_timer_timeout)
	add_child(timer)

func _process(delta):
	time_elapsed += delta
	update_ui()
	
	# Dev mode timer reset
	if dev_press_count > 0:
		dev_press_timer -= delta
		if dev_press_timer <= 0:
			dev_press_count = 0
			print("Dev Mode Reset")

func update_ui():
	if time_label:
		var minutes = int(time_elapsed / 60)
		var seconds = int(time_elapsed) % 60
		time_label.text = "Time: %02d:%02d" % [minutes, seconds]
	if kill_label:
		kill_label.text = "Kills: %d" % kills
		
	# Update XP Bar
	var player = get_tree().get_first_node_in_group("player")
	if player and xp_bar:
		xp_bar.max_value = player.max_experience
		xp_bar.value = player.experience
		if level_label:
			level_label.text = "Level: %d" % player.level

func add_kill():
	kills += 1

func _on_spawn_timer_timeout():
	if not enemy_scene:
		return
		
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		return

	# Spawn enemy at a random position outside the camera view
	# Assuming a standard viewport size approx 1152x648, let's spawn 800 units away
	var angle = randf() * TAU
	var distance = 800.0
	var spawn_pos = player.global_position + Vector2(1, 0).rotated(angle) * distance
	
	var enemy = enemy_scene.instantiate()
	enemy.global_position = spawn_pos
	add_child(enemy)

# Game Over Logic
var game_over_layer: CanvasLayer

func game_over():
	get_tree().paused = true
	if not game_over_layer:
		create_game_over_ui()
	game_over_layer.visible = true

func create_game_over_ui():
	game_over_layer = CanvasLayer.new()
	game_over_layer.process_mode = Node.PROCESS_MODE_ALWAYS # Important: Allow input while paused
	add_child(game_over_layer)
	
	# Background Dim
	var bg = ColorRect.new()
	bg.color = Color(0, 0, 0, 0.5)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	game_over_layer.add_child(bg)
	
	# Center Container for perfect centering
	var center_container = CenterContainer.new()
	center_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	game_over_layer.add_child(center_container)
	
	# VBox for vertical layout
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 20)
	center_container.add_child(vbox)
	
	# Game Over Label
	var label = Label.new()
	label.text = "GAME OVER"
	label.add_theme_font_size_override("font_size", 64)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(label)
	
	# Restart Button
	var restart_btn = Button.new()
	restart_btn.text = "Restart"
	restart_btn.add_theme_font_size_override("font_size", 32)
	restart_btn.pressed.connect(_on_restart_pressed)
	vbox.add_child(restart_btn)
	
	# Exit Button
	var exit_btn = Button.new()
	exit_btn.text = "Exit"
	exit_btn.add_theme_font_size_override("font_size", 32)
	exit_btn.pressed.connect(_on_exit_pressed)
	vbox.add_child(exit_btn)

func _on_restart_pressed():
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_exit_pressed():
	get_tree().quit()

# Level Up Logic
var level_up_scene = preload("res://LevelUpScreen.tscn")
var available_skills = ["attack", "defense", "control", "fire_rate", "bullet_size", "move_speed", "small_player", "bullet_speed", "magnet"]




func on_player_level_up(level):
	# Trigger every 3 levels
	if level % 3 == 0 and available_skills.size() > 0:
		show_level_up_screen()

func show_level_up_screen():
	get_tree().paused = true
	var level_up_screen = level_up_scene.instantiate()
	add_child(level_up_screen)
	level_up_screen.setup(available_skills)
	level_up_screen.skill_selected.connect(_on_skill_selected)

func _on_skill_selected(skill_name):
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.activate_skill(skill_name)
		
	# Remove from available skills
	available_skills.erase(skill_name)
	
	get_tree().paused = false

# Developer Mode
var dev_press_count = 0
var dev_press_timer = 0.0

func _input(event):
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_KP_0:
			dev_press_count += 1
			dev_press_timer = 2.0 # Reset timer window
			print("Dev Mode: ", dev_press_count)
			
			if dev_press_count >= 5:
				print("Dev Mode Activated: Showing Level Up Screen")
				show_level_up_screen()
				dev_press_count = 0
