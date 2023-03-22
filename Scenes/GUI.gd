extends Control

# Adapted from https://www.youtube.com/watch?v=3lgjj7Wccyw

var transition_time_x : float = 1
var transition_time_y : float = 1

var LEVELSPERWORLD : int = 16 

var menu_origin_position := Vector2.ZERO
var menu_origin_size := Vector2.ZERO

var current_menu
var menus = []

var world : int = 1

var levelselect_button := preload("res://Scenes/LevelSelectButton.tscn")

onready var board := get_parent().get_parent()
onready var mainmenu := $MainMenu
onready var levelselect := $LevelSelect
onready var credits := $Credits
onready var maingame := $MainGame
onready var tutorial := $Tutorial
onready var tween := $Tween
onready var level_container := $LevelSelect/CenterContainer/VBoxContainer/GridContainer
onready var timer := $Timer
onready var animation_player := $AnimationPlayer
onready var win_sprite := $MainGameStatic/CenterContainer/Win
onready var laurel := $LevelSelect/CenterContainer/VBoxContainer/CenterContainer/Laurel
onready var red := $MainGameStatic/MarginContainer/VBoxContainer/HBoxContainer/Red/Idle/AnimationPlayer
onready var red_blade := $MainGameStatic/MarginContainer/VBoxContainer/HBoxContainer/Red/Blade

# Called when the node enters the scene tree for the first time.
func _ready():
	get_viewport().connect("size_changed", self, "set_viewport_size")
	current_menu = mainmenu
	set_viewport_size()
	
	for child in get_children():
		if child is MarginContainer:
			menus.append(child)

func set_viewport_size():
	menu_origin_size = get_viewport_rect().size
	menu_origin_position = Vector2((menu_origin_size.x - 576) / 2, 0)
	transition_time_x = menu_origin_size.x * 0.001
	transition_time_y = menu_origin_size.y * 0.001
	
	# Remove all but the proper menu from visibility
	for menu in menus:
		if menu != current_menu:
			menu.rect_global_position = Vector2(-menu_origin_size.x, 0)
		else:
			menu.rect_global_position = menu_origin_position

func to_next(menu : String, direction : String):
	var next_menu = from_string(menu)
	if next_menu == levelselect:
		setup_levelselect()
	
	var transition_time : float
	if direction == "right":
		transition_time = transition_time_x
		next_menu.rect_global_position = Vector2(menu_origin_size.x*2, 0)
		tween.interpolate_property(current_menu, "rect_global_position", current_menu.rect_global_position, Vector2(-menu_origin_size.x*1.2, 0), transition_time, Tween.TRANS_CUBIC, Tween.EASE_OUT )

	elif direction == "left":
		transition_time = transition_time_x
		next_menu.rect_global_position = Vector2(-menu_origin_size.x, 0)
		tween.interpolate_property(current_menu, "rect_global_position", current_menu.rect_global_position, Vector2(menu_origin_size.x*1.5, 0), transition_time, Tween.TRANS_CUBIC, Tween.EASE_OUT )
	
	elif direction == "up":
		transition_time = transition_time_y
		next_menu.rect_global_position = Vector2(0, -menu_origin_size.y)
		tween.interpolate_property(current_menu, "rect_global_position", current_menu.rect_global_position, Vector2(current_menu.rect_global_position.x, menu_origin_size.y), transition_time, Tween.TRANS_CUBIC, Tween.EASE_IN)
	
	elif direction == "down":
		transition_time = transition_time_y
		next_menu.rect_global_position = Vector2(0, menu_origin_size.y)
		tween.interpolate_property(current_menu, "rect_global_position", current_menu.rect_global_position, Vector2(current_menu.rect_global_position.x, -menu_origin_size.y), transition_time, Tween.TRANS_CUBIC, Tween.EASE_OUT)
	tween.interpolate_property(next_menu, "rect_global_position", next_menu.rect_global_position, menu_origin_position, transition_time, Tween.TRANS_CUBIC, Tween.EASE_OUT)
	
	tween.start()

	current_menu = next_menu
	
func from_string(menu : String):
	match menu:
		"mainmenu":
			return mainmenu
		"levelselect":
			return levelselect
		"maingame":
			return maingame
		"tutorial":
			return tutorial
		"credits":
			return credits
		_:
			return mainmenu

func setup_levelselect():
	red.play("idle")
	win_sprite.modulate = Color(1,1,1,0)
	
	for child in level_container.get_children():
		child.queue_free()
	
	for level in range(LEVELSPERWORLD):
		var level_button := levelselect_button.instance()
		
		if Helper.config.get_value("Release", "unlocked")[world][level]:
			level_button.icon = load("res://Sprites/Games/" + str(world) + "-" + str(level + 1) + ".png")
			level_button.connect("pressed", self, "level_select", [level + 1])
		else:
			level_button.icon = load("res://Sprites/lock.png")

		level_container.add_child(level_button)
	
	# if the next world is unlocked, show completion symbol
	laurel.visible = Helper.config.get_value("Release", "unlocked")[world+1][0]

func _on_ComputerPlay_pressed():
	to_next("levelselect", "right")
	board.againstComputer = true

func _on_LocalPlay_pressed():
	to_next("levelselect", "right")
	board.againstComputer = false

func level_select(level : int):
	if board.inGame:
		return
	 
	board.world = world
	board.level = level
	
	board.StartGame()
	board.FromFile()
	board.MakeGame()
	board.Render()
	
	to_next("maingame", "up")
	timer.start()
	yield(timer, "timeout")
	board.CameraAnimator.play("pan_up")
	
	yield(timer, "timeout")
	timer.stop()
	fade_in()

func fade_in():
	animation_player.play("fade_in")
func fade_out():
	animation_player.play("fade_out")
func blue_win():
	red.play('sad')
	win_sprite.texture = load("res://Sprites/bluewin.png")
	win()
func red_win():
	red.play('happy')
	red_blade.animation = 'vanish'
	win_sprite.texture = load("res://Sprites/redwin.png")
	win()

func win():
	
	# tween.interpolate_property(win_sprite, "modulate", Color(1,1,1,0), Color(1,1,1,1), 0.5, Tween.TRANS_CUBIC, Tween.EASE_IN )
	tween.start()

func _on_BackButton_pressed():
	to_next("mainmenu", "left")
	
func _on_Credits_pressed():
	to_next("credits", "right")

func _on_Tutorial_pressed():
	to_next("tutorial", "right")

func _on_Credits_meta_clicked(meta):
	OS.shell_open(str(meta))

func _on_GiveUp_button_down():
	board.GiveUp()

func _on_TabContainer_tab_changed(tab):
	$Tutorial/CenterContainer/VBoxContainer/TabContainer/II/TextureRect/AnimatedSprite.frame = 0
	$Tutorial/CenterContainer/VBoxContainer/TabContainer/III/TextureRect2/AnimatedSprite.frame = 0
	$Tutorial/CenterContainer/VBoxContainer/TabContainer/IV/TextureRect3/AnimatedSprite.frame = 0
