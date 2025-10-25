extends Sprite2D

@export var health_component : HealthComponent

var shader_tween : Tween
func _ready() -> void:
	if is_multiplayer_authority():
		health_component.damaged.connect(on_damaged)

func on_damaged():
	_play_highlight.rpc()

@rpc("authority","call_local")
func _play_highlight():
	if shader_tween != null and shader_tween.is_valid():
		shader_tween.kill()
		
	shader_tween = create_tween()
	shader_tween.tween_property(material, "shader_parameter/percent", 0, .15)\
		.from(1).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_IN)
