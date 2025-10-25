class_name Player
extends CharacterBody2D

signal died

@onready var player_input_synchronizer_component: PlayerInputSynchronizerComponent = $PlayerInputSynchronizerComponent
@onready var weapon_root: Node2D = $Visuals/WeaponRoot
@onready var fire_rate_timer: Timer = $FireRateTimer
@onready var health_component: HealthComponent = $HealthComponent
@onready var label: Label = $Label
@onready var visuals: Node2D = $Visuals
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var barrel_position: Marker2D = $Visuals/WeaponRoot/WeaponAnimationRoot/BarrelPosition
@onready var camera = $Camera2D as Camera2D
@onready var display_name_label: Label = $DisplayNameLabel

var multiplayer_id : int
var bullet_scene : PackedScene = preload("uid://dtilfbcbxlb73")
var muzzle_flash_scene : PackedScene = preload("uid://k6dpwwbpryka")
var label_text : String = "5"
var is_dying : bool
var input_multiplayer_authority : int
var display_name: String =""
const SPEED = 300

func _ready() -> void:
	player_input_synchronizer_component.set_multiplayer_authority(input_multiplayer_authority)
	if multiplayer.multiplayer_peer is OfflineMultiplayerPeer:
		display_name_label.visible = false
	else:
		display_name_label.text = display_name
	
	if multiplayer_id == multiplayer.get_unique_id():
		camera.make_current()
		
	
	if is_multiplayer_authority():
		health_component.died.connect(_on_died)
	#set_process(is_multiplayer_authority()) being removed to add granularity to wich code runs on server x clients
	

func _process(_delta: float) -> void:
	
	update_aim_position()
	
	#this will run only on server (updating position for everyone and relaying to all clients)
	if is_multiplayer_authority():
		if is_dying:
			global_position = Vector2.RIGHT * 2000
			return
		velocity = player_input_synchronizer_component.movement_vector * SPEED
		move_and_slide()
		if player_input_synchronizer_component.is_attack_pressed:
			try_fire()
		label_text = str(health_component.current_health)
	label.text = label_text

func update_aim_position():
	var aim_vector = weapon_root.global_position + player_input_synchronizer_component.aim_vector
	visuals.scale = Vector2.ONE if player_input_synchronizer_component.aim_vector.x >= 0 else Vector2(-1,1) 
	weapon_root.look_at(aim_vector)



func try_fire():
	if !fire_rate_timer.is_stopped():
		return
	var bullet = bullet_scene.instantiate()
	bullet.global_position = barrel_position.global_position	
	bullet.start(player_input_synchronizer_component.aim_vector)
	get_parent().add_child(bullet, true)
	fire_rate_timer.start()
	
	#THIS is a call to the rpc method below that already has the server as the only
	#caller available, so no need to guard bhind is_multiplayer_authority()
	play_fire_effects.rpc()

@rpc("authority","call_local", "unreliable")
func play_fire_effects():
	if animation_player.is_playing():
		animation_player.stop()
	animation_player.play("fire")
	
	var muzzle_flash : Node2D = muzzle_flash_scene.instantiate()
	muzzle_flash.global_position = barrel_position.global_position
	muzzle_flash.rotation = barrel_position.global_rotation
	get_parent().add_child(muzzle_flash)

@rpc("authority","call_local","reliable")
func _kill():
	is_dying = true
	player_input_synchronizer_component.public_visibility = false
	
func set_display_name(_display_name: String):
	self.display_name = _display_name
	
func _on_died():
	kill()
func kill():
	if !is_multiplayer_authority():
		push_error("Cannot Kill on Non-Server Client")
	_kill.rpc()
	await get_tree().create_timer(.5).timeout
	died.emit()
	queue_free()
