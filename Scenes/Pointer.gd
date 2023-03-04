extends Area2D

export var cutting_velocity : float
var cutting := false

func _ready():
	pass

func _process(delta):
	var new_position = get_global_mouse_position()
	var vel = (position - new_position) / delta
	
	position = new_position
	
	if vel.length() > cutting_velocity:
		cutting = true
	else:
		cutting = false

