extends Node

"""
Here, options, saves and the likes are handled.
"""

var config = ConfigFile.new()
var section = "Release"

func new_game():
	var unlocked = []
	for _i in range(8): # expected max number of worlds
		var world = []
		for j in range(16): # expected max number of levels
			world.append(j == 0)
		unlocked.append(world)
	
	config.set_value(section, "unlocked", unlocked)
	config.set_value(section, "volume", 1)
	config.set_value(section, "SFX", 1)
	config.set_value(section, "display_value", false)
	config.set_value(section, "tutorial_seen", false)
	config.set_value(section, "instructions_seen", false)

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
