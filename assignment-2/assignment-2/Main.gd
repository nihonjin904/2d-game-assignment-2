extends Node2D

@export var enemy_scene: PackedScene

# UI Variables
var time_elapsed = 0.0
var kills = 0
var time_label: Label
var kill_label: Label
var hp_label: Label
var xp_bar: ProgressBar

var level_label: Label

var boss_timer = 0.0
var boss_interval = 60.0

const MAP_LIMIT = 5120

var spawn_timer: Timer


var difficulty_timer = 0.0


# Developer Mode
var dev_press_count = 0

var dev_press_timer = 0.0a


func _ready():
	randomize()
	
	# Force set BGM bus
	if has_node("bgm"):
		$bgm.bus = "Music"

	
	# Set Map Boundaries
	# 5x5 tiles of 2048x2048 = 10240x10240
	# Centered at 0,0: -5120 to 5120
	
	var player = $Player
	if player and player.has_node("Camera2D"):
		var camera = player.get_node("Camera2D")
		camera.limit_left = -MAP_LIMIT
		camera.limit_top = -MAP_LIMIT
		camera.limit_right = MAP_LIMIT
		camera.limit_bottom = MAP_LIMIT
		
	# Update Background size to cover the map
	if has_node("Background"):
		var bg = $Background
		# Scale is 0.2, so we need 5x the size to cover the same area
		var bg_limit = MAP_LIMIT * 5
		# We want the visual coverage to be from -map_limit to +map_limit
		# So position should be -map_limit
		# And size should be (map_limit * 2) * 5
		bg.size = Vector2(bg_limit * 2, bg_limit * 2)
		bg.position = Vector2(-MAP_LIMIT, -MAP_LIMIT)

		
		print("BG Debug: Visible=", bg.visible, " Rect=", bg.get_rect(), " GlobalPos=", bg.global_position, " Scale=", bg.scale)



	
	# Create UI Layer

	var canvas_layer = CanvasLayer.new()
	add_child(canvas_layer)
	
	# Create HP Label
	hp_label = Label.new()
	hp_label.set_anchors_preset(Control.PRESET_TOP_LEFT)
	hp_label.position = Vector2(20, 20) # Offset from anchor
	hp_label.modulate = Color(0, 1, 0) # Green
	hp_label.add_theme_font_size_override("font_size", 24)
	canvas_layer.add_child(hp_label)
	
	# Create Time Label
	time_label = Label.new()
	time_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	time_label.position = Vector2(-50, 20) # Centered roughly
	time_label.modulate = Color(1, 1, 1)
	time_label.add_theme_font_size_override("font_size", 24)
	canvas_layer.add_child(time_label)
	
	# Create Kill Label
	kill_label = Label.new()
	kill_label.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	kill_label.position = Vector2(-150, 20) # Offset from right
	kill_label.modulate = Color(1, 0, 0) # Red for kills
	kill_label.add_theme_font_size_override("font_size", 24)
	canvas_layer.add_child(kill_label)
	
	# Create Level Label (Bottom Left)
	level_label = Label.new()
	level_label.text = "Level: 1"
	level_label.add_theme_font_size_override("font_size", 20)
	level_label.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	level_label.position = Vector2(20, -40) # Offset from bottom
	canvas_layer.add_child(level_label)
	
	# Create XP Bar (Bottom, Green, Right of Level Label)
	xp_bar = ProgressBar.new()
	xp_bar.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	xp_bar.position = Vector2(120, -35) # Offset from bottom
	xp_bar.size = Vector2(1000, 20) # Width will be handled by anchors mostly but let's keep it simple
	# Actually, anchors are better.
	xp_bar.anchor_left = 0.1
	xp_bar.anchor_right = 0.9
	xp_bar.anchor_bottom = 1.0
	xp_bar.offset_bottom = -20
	xp_bar.offset_top = -40
	
	xp_bar.show_percentage = false
	xp_bar.modulate = Color(0, 1, 0) # Green
	canvas_layer.add_child(xp_bar)

	# Create a timer for spawning enemies
	spawn_timer = Timer.new()
	spawn_timer.wait_time = 1.0 # Spawn every 1 second
	spawn_timer.autostart = true
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	add_child(spawn_timer)


func _process(delta):
	time_elapsed += delta
	
	# Boss Spawner
	boss_timer += delta
	if boss_timer >= boss_interval:
		spawn_boss()
		boss_timer = 0.0
		
	# Difficulty Scaler (Spawn Rate)
	difficulty_timer += delta
	if difficulty_timer >= 60.0:
		difficulty_timer = 0.0
		spawn_timer.wait_time *= 0.7 # Reduced by 30%
		print("Difficulty Increased: Spawn Interval = ", spawn_timer.wait_time)

		
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
	if player:
		if hp_label:
			hp_label.text = "HP: %d/%d" % [player.current_lives, player.max_lives]
			
		if xp_bar:
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
	# Retry up to 10 times to find a valid position inside the map
	var spawn_pos = Vector2.ZERO
	var valid_pos = false
	
	for i in range(10):
		var angle = randf() * TAU
		var distance = 800.0
		var test_pos = player.global_position + Vector2(1, 0).rotated(angle) * distance
		
		# Check if inside map limits
		if abs(test_pos.x) <= MAP_LIMIT and abs(test_pos.y) <= MAP_LIMIT:
			spawn_pos = test_pos
			valid_pos = true
			break
	
	if not valid_pos:
		# If we couldn't find a valid position, skip spawning this time
		# Or we could clamp as a fallback, but user specifically asked not to spawn outside
		return

	var enemy = enemy_scene.instantiate()
	enemy.global_position = spawn_pos
	add_child(enemy)


func spawn_boss():
	if not enemy_scene:
		return
		
	var boss = enemy_scene.instantiate()
	add_child(boss)
	
	# Spawn randomly around player
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		return
		
	var spawn_pos = Vector2.ZERO
	var valid_pos = false
	
	for i in range(10):
		var angle = randf() * PI * 2
		var distance = 800 # Spawn off-screen
		var test_pos = player.global_position + Vector2(cos(angle), sin(angle)) * distance
		
		if abs(test_pos.x) <= MAP_LIMIT and abs(test_pos.y) <= MAP_LIMIT:
			spawn_pos = test_pos
			valid_pos = true
			break
			
	if not valid_pos:
		# For boss, we really want it to spawn. Fallback to clamping if retries fail.
		var angle = randf() * PI * 2
		spawn_pos = player.global_position + Vector2(cos(angle), sin(angle)) * 800
		spawn_pos.x = clamp(spawn_pos.x, -MAP_LIMIT, MAP_LIMIT)
		spawn_pos.y = clamp(spawn_pos.y, -MAP_LIMIT, MAP_LIMIT)

	
	boss.global_position = spawn_pos

	
	# Initialize boss stats
	boss.init_boss(player.max_experience)
	
	print("BOSS SPAWNED!")


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
	
	# Game Over Background (CG)
	var bg = TextureRect.new()
	
	# Randomly select CG
	var cg_index = randi() % 2
	if cg_index == 0:
		bg.texture = load("res://Game_Over_CG.png")
		Global.unlock_cg("cg1")
	else:
		bg.texture = load("res://Game_Over_CG_2.png")
		Global.unlock_cg("cg2")
		
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
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
	
	# Main Menu Button
	var menu_btn = Button.new()
	menu_btn.text = "Main Menu"
	menu_btn.add_theme_font_size_override("font_size", 32)
	menu_btn.pressed.connect(_on_main_menu_pressed)
	vbox.add_child(menu_btn)
	
	# Exit Button
	var exit_btn = Button.new()

	exit_btn.text = "Exit"
	exit_btn.add_theme_font_size_override("font_size", 32)
	exit_btn.pressed.connect(_on_exit_pressed)
	vbox.add_child(exit_btn)

# Pause Menu Logic
var pause_layer: CanvasLayer
var settings_panel: Control

func _input(event):
	# Dev Mode
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_KP_0:
			dev_press_count += 1
			dev_press_timer = 2.0 # Reset timer window
			print("Dev Mode: ", dev_press_count)
			
			if dev_press_count >= 5:
				print("Dev Mode Activated: Showing Level Up Screen")
				show_level_up_screen()
				dev_press_count = 0
	
	# Pause Menu
	if event.is_action_pressed("ui_cancel"):
		toggle_pause()

func toggle_pause():
	if not pause_layer:
		create_pause_menu()
		
	var is_paused = not get_tree().paused
	get_tree().paused = is_paused
	pause_layer.visible = is_paused
	
	if not is_paused:
		# If unpausing, ensure settings is hidden and main pause menu is shown next time
		if settings_panel:
			settings_panel.hide()
		# We might need to handle showing the main buttons again if we hid them for settings
		var vbox = pause_layer.get_node("CenterContainer/VBoxContainer")
		if vbox:
			vbox.show()

func create_pause_menu():
	pause_layer = CanvasLayer.new()
	pause_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	pause_layer.visible = false
	add_child(pause_layer)
	
	# Background Dim
	var bg = ColorRect.new()
	bg.color = Color(0, 0, 0, 0.5)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	pause_layer.add_child(bg)
	
	# Center Container
	var center_container = CenterContainer.new()
	center_container.name = "CenterContainer"
	center_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	pause_layer.add_child(center_container)
	
	# VBox
	var vbox = VBoxContainer.new()
	vbox.name = "VBoxContainer"
	vbox.add_theme_constant_override("separation", 20)
	center_container.add_child(vbox)
	
	# Label
	var label = Label.new()
	label.text = "PAUSED"
	label.add_theme_font_size_override("font_size", 64)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(label)
	
	# Resume
	var resume_btn = Button.new()
	resume_btn.text = "Resume"
	resume_btn.add_theme_font_size_override("font_size", 32)
	resume_btn.pressed.connect(_on_resume_pressed)
	vbox.add_child(resume_btn)
	
	# Restart
	var restart_btn = Button.new()

	restart_btn.text = "Restart"
	restart_btn.add_theme_font_size_override("font_size", 32)
	restart_btn.pressed.connect(_on_restart_pressed)
	vbox.add_child(restart_btn)
	
	# Settings
	var settings_btn = Button.new()
	settings_btn.text = "Settings"
	settings_btn.add_theme_font_size_override("font_size", 32)
	settings_btn.pressed.connect(_on_pause_settings_pressed)
	vbox.add_child(settings_btn)
	
	# Main Menu Button
	var menu_btn = Button.new()
	menu_btn.text = "Main Menu"
	menu_btn.add_theme_font_size_override("font_size", 32)
	menu_btn.pressed.connect(_on_main_menu_pressed)
	vbox.add_child(menu_btn)
	
	# Exit
	var exit_btn = Button.new()

	exit_btn.text = "Exit"
	exit_btn.add_theme_font_size_override("font_size", 32)
	exit_btn.pressed.connect(_on_exit_pressed)
	vbox.add_child(exit_btn)
	
	# Settings Panel (Instance)
	var settings_scene = load("res://SettingsPanel.tscn")
	if settings_scene:
		settings_panel = settings_scene.instantiate()
		settings_panel.visible = false
		settings_panel.back_pressed.connect(_on_pause_settings_back)
		# Add to center container but hide it initially
		# Actually, let's add it to pause_layer and center it manually or use anchors
		pause_layer.add_child(settings_panel)

func _on_pause_settings_pressed():
	pause_layer.get_node("CenterContainer/VBoxContainer").hide()
	settings_panel.show()

func _on_pause_settings_back():
	settings_panel.hide()
	pause_layer.get_node("CenterContainer/VBoxContainer").show()

func _on_resume_pressed():
	toggle_pause()

func _on_restart_pressed():
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_main_menu_pressed():
	get_tree().paused = false
	get_tree().change_scene_to_file("res://MainMenu.tscn")

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
