class_name HurtboxComponent
extends Area2D

signal was_hit

@export var health_component: HealthComponent

func _ready() -> void:
	self.area_entered.connect(_on_area_entered)
	
func _on_area_entered(other_area : Area2D):
	if !is_multiplayer_authority() or other_area is not HitboxComponent:
		return
	handle_hit.call_deferred(other_area as HitboxComponent)


func handle_hit(hitbox_component :HitboxComponent):
	hitbox_component.register_hurtbox_hit(self)
	health_component.damage(hitbox_component.damage)
	was_hit.emit()
