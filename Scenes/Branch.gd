extends Line2D


signal be_cut(ID)

var ID : int

func _ready():
	var _x = connect("be_cut", get_parent(), "Cut")
	var segment = SegmentShape2D.new()
	
	segment.a = points[0]
	segment.b = points[1]
	$Area2D/CollisionShape2D.shape = segment


func _on_Area2D_area_entered(area):
	if area.is_in_group("pointer"):
		if area.cutting:
			emit_signal("be_cut", ID)
