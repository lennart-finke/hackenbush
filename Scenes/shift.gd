# This little helper script can shift the points of all branches
# when attached to an EdgeContainer node in res://Games

extends Node2D
tool

export var shift : float

func _ready():
	for child in get_children():
		var points = child.get_points()
		for k in range(len(points)):
			points[k][0] += shift
		print(points)
		child.set_points(points)
