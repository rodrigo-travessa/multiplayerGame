class_name HealthComponent
extends Node

#defining a new custom signal
signal died
signal damaged

@export var max_health : int

var current_health : int

func _ready() -> void:
	current_health = max_health

func damage(amount : int ):
	damaged.emit()
	current_health = clamp(current_health - amount, 0, max_health)
	if current_health <= 0:
		died.emit()
