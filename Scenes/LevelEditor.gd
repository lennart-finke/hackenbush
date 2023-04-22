extends Node

var filepath = Helper.level_filepath

onready var edge_container := $Edges
onready var pointer := $Pointer
onready var animation_player := $Camera/AnimationPlayer

var branch := preload("res://Scenes/Branch.tscn")

var mode := "recolor"
var edge_ID : int
var node_IDs : PoolIntArray = []

func _ready():
	var file = File.new()
	if file.file_exists(filepath):
		var container_instance = load(filepath).instance()
		
		for node in container_instance.get_children():
			var points : PoolVector2Array = node.points
			container_instance.remove_child(node)
			label_branch(node, get_node_id(points[0]), get_node_id(points[len(points) - 1]))
			edge_container.add_child(node)
			node.owner = edge_container
			
	edge_ID = edge_container.get_child_count() - 1


func Cut(ID):
	if mode == "add":
		return
	
	var target = null
	for node in edge_container.get_children():
		if node.is_in_group("branch") and node.ID == ID:
			target = node
	
	match mode:
		"delete":
			target.queue_free()
		"recolor":
			target.change_color()

func get_node_id(point : Vector2):
	var course_x = pointer.to_course_x(point.x)
	var course_y = pointer.to_course_y(point.y)
	return (course_x - pointer.min_course_x) + (course_y - pointer.min_course_y) * pointer.range_course_x

func label_branch(b, start_ID : int, end_ID : int):
	b.p = start_ID
	b.q = end_ID
	if !node_IDs.has(start_ID):
		node_IDs.append(start_ID)
	if !node_IDs.has(end_ID):
		node_IDs.append(end_ID)

func try_add_branch(points : PoolVector2Array):
	if len(points) < 2:
		return
	
	var start = points[0]
	var end = points[len(points) - 1]
	
	if (start.y == 0 and end.y == 0) or (start == end):
		return

	var start_ID = get_node_id(start)
	var end_ID = get_node_id(end)
	
	if (!node_IDs.has(start_ID) and !node_IDs.has(end_ID) and start.y != 0 and end.y != 0):
		return
	
	var branch_instance = branch.instance()
	branch_instance.points = points
	edge_ID += 1
	
	label_branch(branch_instance, start_ID, end_ID)
	
	branch_instance.ID = edge_ID
	
	edge_container.add_child(branch_instance)
	# To save branches in a PackedScene later
	branch_instance.owner = edge_container

func _on_Remove_pressed():
	mode = "delete"
	pointer.set_editor_mode(false)

func _on_Recolor_pressed():
	mode = "recolor"
	pointer.set_editor_mode(false)

func _on_Add_pressed():
	mode = "add"
	pointer.set_editor_mode(true)

func _on_Save_pressed():
	save_game()
	
func save_game():
	var ID_dict = {}
	for b in edge_container.get_children():
		if !(b.p in ID_dict):
			ID_dict[b.p] = len(ID_dict)
	
		if !(b.q in ID_dict):
			ID_dict[b.q] = len(ID_dict)

		b.p = ID_dict[b.p]
		b.q = ID_dict[b.q]
		
	var scene = PackedScene.new()
	scene.pack(edge_container)
	ResourceSaver.save(filepath, scene)
	print(filepath)
	animation_player.play("pan_down")

func exit():
	Helper.from_editor = true
	get_tree().change_scene_to(load("res://Scenes/Board.tscn"))

