extends Control



var main_scene: PackedScene = preload("uid://cllxvom2safnd")

#@onready var host_button: Button = $HBoxContainer/HostButton
#@onready var join_button: Button = $HBoxContainer/JoinButton
@onready var single_player_button: Button = $VBoxContainer/SinglePlayerButton
@onready var multi_player_button: Button = $VBoxContainer/MultiPlayerButton
@onready var quit_button: Button = $VBoxContainer/QuitButton

@onready var multiplayer_menu_scene : PackedScene = load("uid://cgnymwf4b6gmk")

var ipAddress : String

func _ready() -> void:
	quit_button.pressed.connect(_on_quit_button_pressed)
	single_player_button.pressed.connect(_on_single_player_button_pressed)
	multi_player_button.pressed.connect(_on_multi_player_button_pressed)





func _on_single_player_button_pressed():
	get_tree().change_scene_to_packed(main_scene)

func _on_multi_player_button_pressed():
	get_tree().change_scene_to_packed(multiplayer_menu_scene)

func _on_quit_button_pressed():
	get_tree().quit()
