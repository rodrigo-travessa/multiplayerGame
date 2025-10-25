extends CanvasLayer

@export var enemy_manager : EnemyManager
@onready var round_label: Label = $MarginContainer/VBoxContainer/RoundLabel
@onready var timer_label: Label = $MarginContainer/VBoxContainer/TimerLabel


func _ready() -> void:
	enemy_manager.round_changed.connect(on_round_began)

func _process(_delta: float) -> void:
	timer_label.text = str(ceili(enemy_manager.get_round_timer_remaining()))
	
	pass

func on_round_began(round_number : int):
	round_label.text = "Round: %s " % str(round_number)
