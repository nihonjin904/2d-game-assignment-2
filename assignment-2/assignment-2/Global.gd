extends Node

var music_bus_index
var sfx_bus_index

var unlocked_cgs = {
	"cg1": false,
	"cg2": false
}

const SAVE_PATH = "user://savegame.save"


func _ready():
	# Initialize bus indices
	music_bus_index = AudioServer.get_bus_index("Music")
	sfx_bus_index = AudioServer.get_bus_index("SFX")
	
	# Create buses if they don't exist (fallback, though usually set in editor)
	# Actually, we should assume they exist or create them.
	# Creating them via code is complex because AudioServer layout is usually project setting.
	# We will assume user (or I) will set them up in default_bus_layout.tres or we just use "Master" if missing.
	# But the plan said "Implement Audio Settings (BGM, SFX Buses)".
	# I should probably create a default_bus_layout.tres or just add them if possible?
	# AudioServer.add_bus() can be used.
	
	if music_bus_index == -1:
		AudioServer.add_bus()
		music_bus_index = AudioServer.get_bus_count() - 1
		AudioServer.set_bus_name(music_bus_index, "Music")
		AudioServer.set_bus_send(music_bus_index, "Master")
		
	if sfx_bus_index == -1:
		AudioServer.add_bus()
		sfx_bus_index = AudioServer.get_bus_count() - 1
		AudioServer.set_bus_name(sfx_bus_index, "SFX")
		AudioServer.set_bus_send(sfx_bus_index, "Master")
		
	load_data()


func unlock_cg(cg_id):
	if cg_id in unlocked_cgs:
		if not unlocked_cgs[cg_id]:
			unlocked_cgs[cg_id] = true
			save_data()

func save_data():
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_var(unlocked_cgs)

func load_data():
	if FileAccess.file_exists(SAVE_PATH):
		var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
		if file:
			var data = file.get_var()
			if data is Dictionary:
				# Merge loaded data with default to handle new keys if any
				for key in data:
					if key in unlocked_cgs:
						unlocked_cgs[key] = data[key]

func set_bus_volume(bus_name, value_db):

	var index = AudioServer.get_bus_index(bus_name)
	if index != -1:
		AudioServer.set_bus_volume_db(index, value_db)
		AudioServer.set_bus_mute(index, value_db <= -30) # Mute if very low

func get_bus_volume(bus_name):
	var index = AudioServer.get_bus_index(bus_name)
	if index != -1:
		return AudioServer.get_bus_volume_db(index)
	return 0.0
