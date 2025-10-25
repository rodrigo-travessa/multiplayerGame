class_name Bullet
extends Node2D

const SPEED : int = 600
var bullet_direction : Vector2

@onready var hitbox_component: HitboxComponent = $HitboxComponent
@onready var life_timer: Timer = $LifeTimer

func _ready() -> void:
	hitbox_component.hit_hurtbox.connect(_on_hit_hurtbox)
	life_timer.timeout.connect(_on_lifetimer_timeout)

func _process(delta : float):
	global_position += bullet_direction * SPEED * delta

func start(direction : Vector2):
	bullet_direction = direction
	rotation = direction.angle()

func _on_lifetimer_timeout():
	if is_multiplayer_authority():
		queue_free()

func register_collision():
	queue_free()

func _on_hit_hurtbox(_hurtbox : HurtboxComponent):
	register_collision()
