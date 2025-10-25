extends CharacterBody2D

#@onready var area_2d: Area2D = $Area2D
@onready var target_timer: Timer = $TargetTimer
@onready var health_component: HealthComponent = $HealthComponent
@onready var visuals: Node2D = $Visuals
@onready var attack_cooldown_timer: Timer = $AttackCooldownTimer
@onready var charge_attack_timer: Timer = $ChargeAttackTimer
@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D
@onready var hitbox_collision_shape: CollisionShape2D = %HitboxCollisionShape
@onready var alert_sprite: Sprite2D = $AlertSprite
@onready var hurtbox_component: HurtboxComponent = $HurtboxComponent


@export var SPEED : int = 40

var ground_particles_scene : PackedScene = preload("uid://d22xbpwx4s3j7")
var impact_particles_scene : PackedScene = preload("uid://go15vmd340gb")
var target_position : Vector2
var state_machine : CallableStateMachine = CallableStateMachine.new()
var default_collision_mask : int
var default_collision_layer : int
var alert_tween : Tween

var current_state : String :
	get:
		return state_machine.current_state
	set(value):
		var state: Callable = Callable.create(self, value)
		state_machine.change_state(state)

func _notification(what: int) -> void:
	if what == NOTIFICATION_SCENE_INSTANTIATED:
		state_machine.add_states(state_spawn, enter_state_spawn, Callable())
		state_machine.add_states(state_normal, enter_state_normal,Callable())
		state_machine.add_states(state_charge_attack, enter_state_charge_attack, leave_state_charge_attack)
		state_machine.add_states(state_attack, enter_state_attack, leave_state_attack)
		


func _ready():
	default_collision_layer = collision_layer
	default_collision_mask = collision_mask
	hitbox_collision_shape.disabled = true
	alert_sprite.scale = Vector2.ZERO
	
	if is_multiplayer_authority():
		state_machine.set_initial_state(state_spawn)
		health_component.died.connect(_on_died)
		hurtbox_component.was_hit.connect(_on_was_hit)

func _process(_delta: float) -> void:
	state_machine.update()
	
	if is_multiplayer_authority():		
		move_and_slide()

func _on_was_hit():
	if is_multiplayer_authority():
		spawn_hit_particles.rpc()

@rpc("authority","call_local")
func spawn_hit_particles():
	var hit_particles : Node2D = impact_particles_scene.instantiate()
	hit_particles.global_position = hurtbox_component.global_position
	get_parent().add_child(hit_particles)
	
@rpc("authority","call_local")
func spawn_death_particles():
	var death_particles : Node2D = ground_particles_scene.instantiate()
	var background_node: Node = Main.background_mask
	if !is_instance_valid(background_node):
		background_node = get_parent()
	Main.background_mask.add_child(death_particles)
	death_particles.global_position = global_position
	

func enter_state_spawn():
	var tween := create_tween()
	tween.tween_property(visuals, "scale", Vector2.ONE, .3).from(Vector2.ZERO)\
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.finished.connect(func():
		state_machine.change_state(state_normal)
	)

func state_spawn():
	pass

func enter_state_normal():
	if is_multiplayer_authority():
		_acquire_target()
		target_timer.start()

func state_normal():
	if is_multiplayer_authority():
		velocity = global_position.direction_to(target_position) * SPEED
		
		if target_timer.is_stopped():
			_acquire_target()
			target_timer.start()
			
		if attack_cooldown_timer.is_stopped() and global_position.distance_to(target_position) < 180:
			state_machine.change_state(state_charge_attack)
			
	flip()

func enter_state_charge_attack():
	if is_multiplayer_authority():
		_acquire_target()
		charge_attack_timer.start()
	
	if alert_tween != null and alert_tween.is_valid():
		alert_tween.kill()
	alert_tween = create_tween()
	alert_tween.tween_property(alert_sprite, "scale", Vector2.ONE, .2)\
	.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	flip()

func state_charge_attack():
	if is_multiplayer_authority():
		velocity = velocity.lerp(Vector2.ZERO, 1.0 - exp(-15 * get_process_delta_time()))
		if charge_attack_timer.is_stopped():
			state_machine.change_state(state_attack)

func leave_state_charge_attack():
	if alert_tween != null and alert_tween.is_valid():
		alert_tween.kill()
	alert_tween = create_tween()
	alert_tween.tween_property(alert_sprite, "scale", Vector2.ZERO, .2)\
	.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_BACK)

	
func enter_state_attack():
	# this is a bitmask. Basically an integer in binary is 00000001
	# so each number in the binary represents a layer in the collision mask of the inspector.
	# so 111111111111111111111111111 = all collision selected, 100000000000000  
	# only the first layer selected.	
	if is_multiplayer_authority():	
		collision_mask = 1 << 0
		collision_layer = 0
		hitbox_collision_shape.disabled = false
		_acquire_target()
		velocity = global_position.direction_to(target_position) * 900

func state_attack():
	if is_multiplayer_authority():
		velocity = velocity.lerp(Vector2.ZERO, 1.0 - exp(-7 * get_process_delta_time()))
		if velocity.length() < 25:
			state_machine.change_state(state_normal)

func leave_state_attack():
	if is_multiplayer_authority():
		collision_layer = default_collision_layer
		collision_mask = default_collision_mask
		hitbox_collision_shape.disabled = true
		attack_cooldown_timer.start()

func _acquire_target():
	var players = get_tree().get_nodes_in_group("player")
	var nearest_player : Player = null
	var nearest_square_distance: float
	
	for player in players:
		if nearest_player == null:
			nearest_player = player
			nearest_square_distance = nearest_player.global_position.distance_squared_to(global_position)
			continue
		var player_squared_distance : float = player.global_position.distance_squared_to(global_position)
		if player_squared_distance < nearest_square_distance:
			nearest_square_distance = player_squared_distance
			nearest_player = player
	if nearest_player != null:
		target_position = nearest_player.global_position

func flip():
	visuals.scale = Vector2.ONE if global_position.x < target_position.x \
		else Vector2(-1,1)

func _on_died():
	spawn_death_particles.rpc()
	GameEvents.emit_enemy_died()
	queue_free()
