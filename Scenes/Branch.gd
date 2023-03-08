extends Line2D
tool

signal be_cut(ID)

export var ID : int
export var p : int
export var q : int

func _ready():
	var _x = connect("be_cut", get_parent().get_parent(), "Cut")
	
	for i in range(len(points) - 1):
		var collision_shape = CollisionShape2D.new()
		var segment = SegmentShape2D.new()
		
		segment.a = points[i]
		segment.b = points[i+1]
		collision_shape.shape = segment
		$Area2D.call_deferred("add_child", collision_shape)

func die():
	remove_from_group("branch")
	$Area2D.queue_free()
	$AnimationPlayer.play("die")

func die_but_really_this_time():
	get_parent().remove_child(self)
	queue_free()

func _on_Area2D_area_entered(area):
	if area.is_in_group("pointer"):
		if area.cutting:
			call_deferred("emit_signal", "be_cut", ID)
