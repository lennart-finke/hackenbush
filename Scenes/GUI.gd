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

const MAX_WORLD = 2
var world : int = 1
var to_editor := false

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
onready var next_button := $LevelSelect/CenterContainer/VBoxContainer/VBoxContainer/NextButton
onready var red := $MainGameStatic/MarginContainer/HBoxContainer/Red/Idle/AnimationPlayer
onready var red_blade := $MainGameStatic/MarginContainer/HBoxContainer/Red/Blade
onready var blue := $MainGameStatic/MarginContainer/HBoxContainer/Blue/Idle/AnimationPlayer
onready var blue_blade := $MainGameStatic/MarginContainer/HBoxContainer/Blue/Blade
onready var music := $Music
onready var SFX := $SFX
onready var SFX_button := $MainMenu/CenterContainer/VBoxContainer/CenterContainer2/VBoxContainer/HBoxContainer/SFX
onready var visibility_button := $MainMenu/CenterContainer/VBoxContainer/CenterContainer2/VBoxContainer/HBoxContainer/Nodes
onready var play_button := $MainMenu/CenterContainer/VBoxContainer/CenterContainer2/VBoxContainer/Play
onready var toggle_button := $MainMenu/CenterContainer/VBoxContainer/CenterContainer2/VBoxContainer/HBoxContainer/LocalPlay

func to_story():
	to_next("maingame", "down")
	timer.start()
	timer.wait_time = 1
	yield(timer, "timeout")
	get_tree().change_scene("res://Scenes/Theater.tscn")

func _ready():
	get_viewport().connect("size_changed", self, "set_viewport_size")
	current_menu = mainmenu
	set_viewport_size()
	
	setup_sound(Helper.config.get_value(Helper.section, "SFX"))
	
	visibility_button.icon = load("res://Sprites/visible.png" if Helper.config.get_value(Helper.section, "display_nodes") else "res://Sprites/invisible.png")
	
	for child in get_children():
		if child is MarginContainer:
			menus.append(child)
	
	if Helper.from_editor:
		mainmenu.rect_global_position.y = -2000
		world = 0
		to_editor = true
		to_next("levelselect", "down")
	
	elif Helper.from_intro:
		mainmenu.rect_global_position.y = 2000
		world = 1
		Helper.from_intro = false
		
		if Helper.config.get_value(Helper.section, "tutorial_seen"):
			to_next("levelselect", "up")
			timer.start()
			yield(timer, "timeout")
		
		else:
			Helper.config.set_value(Helper.section, "tutorial_seen", true)
			to_next("maingame", "up")
			timer.start()
			yield(timer, "timeout")
			level_select(1)
	
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
	if event == MainLoop.NOTIFICATION_WM_QUIT_REQUEST or event == MainLoop.NOTIFICATION_WM_GO_BACK_REQUEST:
		if board == null:
			return
		if current_menu != mainmenu:
			if board.inGame:
				board.GiveUp()
			else:
				to_next("mainmenu", "left")
		else:
			get_tree().quit()
		
		

func setup_levelselect():
	maingame_static.rect_position = Vector2(0,2000)
	
	red.play("idle")
	blue.play("idle")
	
	win_sprite.modulate = Color(1,1,1,0)
	
	for child in level_container.get_children():
		child.queue_free()
	
	var color = Color("005f73" if world % 2 == 0 else "ae2012")
	
	var normal_stylebox  : StyleBoxFlat = load("res://Theme/normal_stylebox.tres")
	var pressed_stylebox : StyleBoxFlat = load("res://Theme/pressed_stylebox.tres")
	var hover_stylebox : StyleBoxFlat = load("res://Theme/hover_stylebox.tres")
	normal_stylebox.border_color = color
	pressed_stylebox.border_color = color
	hover_stylebox.border_color = color
	
	for level in range(LEVELSPERWORLD):
		var level_button := levelselect_button.instance()
		
		if Helper.config.get_value("Release", "unlocked")[world][level]:
			var file_path = "res://Sprites/Games/" + str(world) + "-" + str(level + 1) + ".png"
			if world != 0:
				level_button.icon = load(file_path)
			if level_button.icon == null:
				level_button.text = str(level + 1)
			level_button.connect("pressed", self, "level_select", [level + 1])
		else:
			level_button.icon = load("res://Sprites/lock.png")

		level_button.add_stylebox_override("normal", normal_stylebox)
		level_button.add_stylebox_override("pressed", pressed_stylebox)
		level_button.add_stylebox_override("hover", hover_stylebox)
		
		level_container.add_child(level_button)
	
	var complete = Helper.config.get_value("Release", "unlocked")[world+1][0] && Helper.config.get_value("Release", "unlocked")[world][15]
	laurel.texture = load("res://Sprites/puzzle.png" if world == 0 else "res://Sprites/laurel.png")
	laurel.modulate = Color(1, 1, 1, 1 if complete or world == 0 else 0)
	next_button.modulate = Color(1, 1, 1, 1 if world != 0 else 0)
	next_button.disabled = world == 0

func level_select(level : int):
	if board.inGame:
		return
	
	SFX.stream = load("res://Sound/click.wav")
	SFX.play()
	
	if to_editor:
		Helper.level_filepath = "user://0-" + str(level) + ".tscn"
		to_next("maingame", "up")
		timer.start()
		yield(timer, "timeout")
		get_tree().change_scene("res://Scenes/LevelEditor.tscn")
	
	maingame_static.rect_position = Vector2.ZERO
	
	board.world = world
	board.level = level
	
	board.StartGame()
	board.FromFile()
	
	if !music.playing:
		music.stream = load("res://Sound/Up2.mp3")
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
		music.stream = load("res://Sound/Down3.mp3")
		music.play()
	win_sprite.texture = load("res://Sprites/bluewin.png")
	win()
func red_win():
	red.play('happy')
	blue.play('sad')
	win_sprite.texture = load("res://Sprites/redwin.png")
	music.stream = load("res://Sound/Down2.mp3")
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
	world = 1
	to_next("levelselect", "right")
	to_editor = false
	if !music.playing:
		music.stream = load("res://Sound/Down.mp3")
		music.play()

func _on_BackButton_pressed():
	match world:
		0:
			if to_editor:
				world = 1
				to_next("mainmenu", "left")
			else:
				world = MAX_WORLD
				setup_levelselect()
			
		1:
			to_next("mainmenu", "left")
		_:
			world -= 1
			setup_levelselect()
		
	
func _on_Credits_pressed():
	to_next("credits", "right")

func _on_Tutorial_pressed():
	to_next("tutorial", "right")

func _on_Credits_meta_clicked(meta):
	OS.shell_open(str(meta))

func _on_GiveUp_button_down():
	if !music.playing:
		music.stream = load("res://Sound/Down.mp3")
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

func _on_Visiblility_pressed():
	var visibility = !Helper.config.get_value(Helper.section, "display_nodes")
	Helper.config.set_value(Helper.section, "display_nodes", visibility)
	Helper.save()
	visibility_button.icon = load("res://Sprites/visible.png" if visibility else "res://Sprites/invisible.png")

func _on_NextButton_pressed():
	world = 0 if world == MAX_WORLD else (world + 1)
	setup_levelselect()

func _on_2Player_pressed():
	var com : bool = !board.againstComputer
	board.againstComputer = com
	toggle_button.icon = load("res://Sprites/2P.png" if com else "res://Sprites/1P.png")
	play_button.icon = load("res://Sprites/1P.png" if com else "res://Sprites/2P.png")
	play_button.text = "1PLAYER" if com else "2PLAYER"

func _on_LevelEditor_pressed():
	to_editor = true
	world = 0
	to_next("levelselect", "right")
