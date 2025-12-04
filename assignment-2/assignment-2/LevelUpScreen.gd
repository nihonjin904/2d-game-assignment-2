extends CanvasLayer

signal skill_selected(skill_name)

var skill_names = {
	"attack": "Attack (Triple Shot)",
	"defense": "Defense (Passive Armor)",
	"control": "Control (Slow Field)",
	"fire_rate": "Fire Rate (+25%)",
	"bullet_size": "Big Bullets (+25% Size)",
	"move_speed": "Move Speed (+50%)",
	"small_player": "Tiny Player (50% Size)",
	"bullet_speed": "Bullet Speed (+10%)",
	"magnet": "Magnet (Attract Loot)"
}



func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS # Allow input while game is paused

func setup(available_skills: Array):
	# Clear existing buttons (except label)
	for child in $CenterContainer/VBoxContainer.get_children():
		if child is Button:
			child.queue_free()
			
	# Create new buttons
	for skill in available_skills:
		var btn = Button.new()
		if skill in skill_names:
			btn.text = skill_names[skill]
		else:
			btn.text = skill
			
		btn.add_theme_font_size_override("font_size", 24)
		btn.pressed.connect(_on_skill_button_pressed.bind(skill))
		$CenterContainer/VBoxContainer.add_child(btn)

func _on_skill_button_pressed(skill_name):
	skill_selected.emit(skill_name)
	queue_free()
