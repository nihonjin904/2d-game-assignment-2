extends Node

var music_bus_index
var sfx_bus_index

var unlocked_cgs = {
	"cg1": false,
	"cg2": false
}

const SAVE_PATH = "user://savegame.save"


func _ready():
	# Force load the bus layout
	var bus_layout = load("res://default_bus_layout.tres")
	if bus_layout:
		AudioServer.set_bus_layout(bus_layout)
		print("Global: Forced loaded default_bus_layout.tres")

	# Initialize bus indices
	music_bus_index = AudioServer.get_bus_index("Music")
	sfx_bus_index = AudioServer.get_bus_index("SFX")

	
	# Fallback: Create buses if they don't exist (common issue in exports if layout isn't loaded)
	if music_bus_index == -1:
		AudioServer.add_bus()
		music_bus_index = AudioServer.get_bus_count() - 1
		AudioServer.set_bus_name(music_bus_index, "Music")
		AudioServer.set_bus_send(music_bus_index, "Master")
		print("Global: Created Music bus at index ", music_bus_index)
		
	if sfx_bus_index == -1:
		AudioServer.add_bus()
		sfx_bus_index = AudioServer.get_bus_count() - 1
		AudioServer.set_bus_name(sfx_bus_index, "SFX")
		AudioServer.set_bus_send(sfx_bus_index, "Master")
		print("Global: Created SFX bus at index ", sfx_bus_index)

	
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
