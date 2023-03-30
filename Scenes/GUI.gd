extends Control

# Using a design idea from https://www.youtube.com/watch?v=3lgjj7Wccyw

var languages = TranslationServer.get_loaded_locales()
var language_index = 0

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
onready var maingame_static := $MainGameStatic
onready var tutorial := $Tutorial
onready var tween := $Tween
onready var level_container := $LevelSelect/CenterContainer/VBoxContainer/GridContainer
onready var timer := $Timer
onready var animation_player := $AnimationPlayer
onready var win_sprite := $MainGameStatic/CenterContainer/Win
onready var laurel := $LevelSelect/CenterContainer/VBoxContainer/CenterContainer/Laurel
onready var red := $MainGameStatic/MarginContainer/HBoxContainer/Red/Idle/AnimationPlayer
onready var red_blade := $MainGameStatic/MarginContainer/HBoxContainer/Red/Blade
onready var blue := $MainGameStatic/MarginContainer/HBoxContainer/Blue/Idle/AnimationPlayer
onready var blue_blade := $MainGameStatic/MarginContainer/HBoxContainer/Blue/Blade
onready var music := $Music
onready var SFX := $SFX
onready var SFX_button := $MainMenu/CenterContainer/VBoxContainer/CenterContainer2/VBoxContainer/HBoxContainer/SFX
# Called when the node enters the scene tree for the first time.
func _ready():
	get_viewport().connect("size_changed", self, "set_viewport_size")
	current_menu = mainmenu
	set_viewport_size()
	
	setup_sound(Helper.config.get_value(Helper.section, "SFX"))
	
	for child in get_children():
		if child is MarginContainer:
			menus.append(child)
	
	# We find the language code used:
	var lang := OS.get_locale_language()
	var i : int = 0
	for l in languages:
		if lang == l:
			language_index = i
			return
		i += 1

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


func _notification(event):
	if board == null:
		return
	if board.inGame or current_menu == mainmenu:
		return
	
	if event == MainLoop.NOTIFICATION_WM_QUIT_REQUEST or event == MainLoop.NOTIFICATION_WM_GO_BACK_REQUEST: 
		to_next("mainmenu", "left")

func setup_levelselect():
	maingame_static.rect_position = Vector2(0,2000)
	
	red.play("idle")
	blue.play("idle")
	
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

func level_select(level : int):
	if board.inGame:
		return
	
	SFX.stream = load("res://Sound/click.wav")
	SFX.play()
	
	maingame_static.rect_position = Vector2.ZERO
	
	board.world = world
	board.level = level
	
	board.StartGame()
	board.FromFile()
	board.MakeGame()
	board.Render()
	
	if !music.playing:
		music.stream = load("res://Sound/Up2.wav")
		music.play()
	
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
	blue.play('happy')
	if !music.playing:
		music.stream = load("res://Sound/Down3.wav")
		music.play()
	win_sprite.texture = load("res://Sprites/bluewin.png")
	win()
func red_win():
	red.play('happy')
	blue.play('sad')
	win_sprite.texture = load("res://Sprites/redwin.png")
	music.stream = load("res://Sound/Down2.wav")
	music.play()
	win()

func win():
	SFX.stream = load("res://Sound/cannon.wav")
	SFX.play()
	
	red_blade.animation = 'vanish'
	blue_blade.animation = 'vanish'
	# tween.interpolate_property(win_sprite, "modulate", Color(1,1,1,0), Color(1,1,1,1), 0.5, Tween.TRANS_CUBIC, Tween.EASE_IN )
	tween.start()

func _on_ComputerPlay_pressed():
	to_next("levelselect", "right")
	if !music.playing:
		music.stream = load("res://Sound/Down.wav")
		music.play()
	board.againstComputer = true

func _on_LocalPlay_pressed():
	to_next("levelselect", "right")
	if !music.playing:
		music.stream = load("res://Sound/Down.wav")
		music.play()
	board.againstComputer = false

func _on_BackButton_pressed():
	to_next("mainmenu", "left")
	
func _on_Credits_pressed():
	to_next("credits", "right")

func _on_Tutorial_pressed():
	to_next("tutorial", "right")

func _on_Credits_meta_clicked(meta):
	OS.shell_open(str(meta))

func _on_GiveUp_button_down():
	if !music.playing:
		music.stream = load("res://Sound/Down.wav")
		music.play()
	board.GiveUp()

func _on_TabContainer_tab_changed(_tab):
	_on_Button_pressed()
	$Tutorial/CenterContainer/VBoxContainer/TabContainer/II/TextureRect/AnimatedSprite.frame = 0
	$Tutorial/CenterContainer/VBoxContainer/TabContainer/III/TextureRect2/AnimatedSprite.frame = 0
	$Tutorial/CenterContainer/VBoxContainer/TabContainer/IV/TextureRect3/AnimatedSprite.frame = 0

func _on_Language_pressed():
	language_index = (language_index + 1) % len(languages)
	TranslationServer.set_locale(languages[language_index])

func _on_Button_pressed():
	SFX.stream = load("res://Sound/click.wav")
	SFX.play()

func _on_SFX_pressed():
	var sound := !bool(Helper.config.get_value(Helper.section, "SFX"))
	
	setup_sound(sound)
	
	Helper.config.set_value(Helper.section, "SFX", sound)
	Helper.save()

func setup_sound(mute : bool):
	SFX.playing = false
	music.playing = false
	
	# Hacky, but it works: We adjust the max distance instead of volume.
	SFX.max_distance = 1 if mute else 2000
	music.max_distance = 1 if mute else 2000
	SFX_button.icon = load("res://Sprites/nosfx.png" if mute else "res://Sprites/sfx.png")
