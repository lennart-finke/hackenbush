extends Area2D

onready var trail = $Node/Trail
onready var branch := $Node/Branch
onready var collision_trail : SegmentShape2D = $CollisionShape2D.shape

export var max_length : int = 10
export var courseness : int = 50
var cutting := false

# Some variables for editor mode
var editor_mode := false
var clicked := false
var max_course_x : int =  int(270 / courseness) 
var min_course_x : int = -int(270 / courseness) 
var max_course_y : int = 0
var min_course_y : int = -int(790 / courseness) 
var range_course_x = max_course_x - min_course_x
var range_course_y = max_course_y - min_course_y
func set_editor_mode(b : bool):
	editor_mode = b
	trail.visible = !editor_mode
	branch.visible = editor_mode

func set_color(c : Color):
	trail.default_color = c

func _process(_delta):
	var new_position = get_global_mouse_position()
	
	if !editor_mode:
		if cutting:
			collision_trail.b = position - new_position
			trail.add_point(global_position)
		elif len(trail.points) > 0:
			trail.remove_point(0)
		while trail.get_point_count() > max_length:
			trail.remove_point(0)
		
		if Input.is_action_pressed("click"):
			cutting = true
		else:
			cutting = false
	
	else:
		var course_x = to_course_x(new_position.x)
		var course_y = to_course_y(new_position.y)
		
		var new_position_mod = Vector2(course_x * courseness, course_y * courseness)
		branch.end.position = new_position_mod
		
		if clicked:
			branch.points = PoolVector2Array([branch.start.position, branch.end.position])
		else:
			branch.start.position = new_position_mod
		
		branch.end.modulate = Color("#005f73" if course_y == 0 else "#001219")
	position = new_position

func to_course_x(x):
	return int(clamp(x / courseness, min_course_x, max_course_x))
func to_course_y(y):
	return int(clamp(y / courseness, min_course_y, max_course_y))

func _input(event):
	if !editor_mode:
		return
		
	if event.is_action_pressed("click") and not event is InputEventScreenDrag:
		clicked = true
		var new_position = get_global_mouse_position()
		var course_x = to_course_x(new_position.x)
		var course_y = to_course_y(new_position.y)
		
		var new_position_mod = Vector2(course_x * courseness, course_y * courseness)
		branch.start.position = new_position_mod
	
	elif event.is_action_released("click") and clicked:
		clicked = false
		get_parent().try_add_branch(branch.points)
		branch.points = PoolVector2Array()
