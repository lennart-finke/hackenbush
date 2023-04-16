extends Node

"""
Here, options, saves and the likes are handled.
"""

var config = ConfigFile.new()
var section = "Release"

# For saving user-created levels
var level_filepath = ""
var from_editor := false
var from_intro := false

func new_game():
	# world 0 is for custom levels
	var unlocked = []
	for i in range(8): # expected max number of worlds
		var world = [i < 2]
		for _j in range(15): # expected max number of levels
			world.append(i == 0)
		unlocked.append(world)
	
	config.set_value(section, "unlocked", unlocked)
	config.set_value(section, "volume", 1)
	config.set_value(section, "SFX", true)
	config.set_value(section, "display_value", false)
	config.set_value(section, "display_nodes", false)
	config.set_value(section, "tutorial_seen", false)
	config.set_value(section, "instructions_seen", false)

func unlock_all():
	var unlocked = []
	for _i in range(8): # expected max number of worlds
		var world = []
		for _j in range(16): # expected max number of levels
			world.append(true)
		unlocked.append(world)
	
	config.set_value(section, "unlocked", unlocked)
	save()

func unlock(world, level):
	# Unlocks the level that comes after world,level and saves.
	var unlocked = config.get_value(section, "unlocked")
	if level == 16:
		unlocked[world + 1][0] = true
	else:
		unlocked[world][level] = true
	config.set_value(section, "unlocked", unlocked)
	save()

func save():
	config.save("user://gamefile.cfg")

func _ready():
	var err = config.load("user://gamefile.cfg")
	if err != OK:
		print("Error loading file! Generating new file...")
		new_game()
		save()
	# We fix old save files. Remove in a subsesequent version.
	if !config.has_section_key(Helper.section, "display_nodes"):
		config.set_value(Helper.section, "display_nodes", false)
