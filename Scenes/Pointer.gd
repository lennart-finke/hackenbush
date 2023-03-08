extends Area2D

onready var trail = $Node/Trail

export var max_length : int = 10
export var cutting_velocity : float
var cutting := false

func set_color(c : Color):
	trail.default_color = c

func _process(delta):
	var new_position = get_global_mouse_position()
	var vel = (position - new_position) / delta
	
	position = new_position
	
	if vel.length() > cutting_velocity and Input.is_action_pressed("click"):
		cutting = true
	else:
		cutting = false
	
	if cutting:
		trail.add_point(global_position)
	elif len(trail.points) > 0:
		trail.remove_point(0)
	while trail.get_point_count() > max_length:
		trail.remove_point(0)

