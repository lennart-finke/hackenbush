extends Node2D

var finished := false
var k := 1

onready var timer := $Timer
onready var animation := $AnimationPlayer
onready var camera := $Camera2D/AnimationPlayer
onready var player := $AudioStreamPlayer2D
onready var text := $CanvasLayer/GUI/MarginContainer/Label

func _ready():
	camera.play_backwards("pan_up")

func start_timer():
	timer.start()

func increment_text():
	if finished:
		text.percent_visible = 1
		return
	text.visible_characters += 1
	player.pitch_scale = 0.5 + 0.2 * randf()
	player.play()
	if text.percent_visible >= 1:
		finished = true

func _input(event):
	if (event.is_action_pressed("click") or event.is_action_pressed("ui_accept")):
		if !finished:
			if animation.current_animation != "2" && animation.current_animation != "5":
				animation.seek(animation.current_animation_length)
			print(animation.current_animation_position)
			finished = true
			return
		if k > 5:
			finish()
			return
		proceed()
		
func proceed():
	finished = false
	k += 1
	animation.play(str(k))
	text.text = "STORY" + str(k)
	text.percent_visible = 0

func play(a : String):
	animation.play(a)

func finish():
	camera.play("pan_up")
	timer.wait_time = 3
	timer.start()
	yield(timer, "timeout")
	change_scene()

func change_scene():
	Helper.from_intro = true
	get_tree().change_scene("res://Scenes/Board.tscn")
