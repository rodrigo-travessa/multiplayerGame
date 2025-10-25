class_name EnemyManager
extends Node

signal round_changed(round_number:int)
signal round_completed
signal game_completed

@export var enemy_scene : PackedScene 
@export var enemy_spawn_root : Node
@export var spawn_rect : ReferenceRect
@onready var spawn_interval_timer: Timer = $SpawnIntervalTimer
@onready var round_timer: Timer = $RoundTimer

const ROUND_BASE_TIME: int = 10
const ROUND_GROWTH := 5
const BASE_ENEMY_SPAWN_TIME : float = 1
const ENEMY_SPAWN_TIME_GROWTH : float = -0.15
const MAX_WAVE : int = 10

var _round_count : int
var round_count : int:
	get:
		return _round_count
	set(val):
		_round_count = val
		round_changed.emit(_round_count)
var spawned_enemies: int = 0

func _ready() -> void:
	spawn_interval_timer.timeout.connect(_on_spawn_interval_timer_timeout)
	round_timer.timeout.connect(_on_round_timer_timeout)
	GameEvents.enemy_died.connect(_on_enemy_died)
	if is_multiplayer_authority():
		_begin_round()

@rpc("authority","call_remote", "reliable")
func _synchronize(data :Dictionary):
	var wait_time : float = data["round_timer_time_left"]
	if wait_time >0:
		round_timer.wait_time = wait_time
	if data["round_timer_is_running"]:
		round_timer.start()
	round_count = data["round_count"]

func synchronize(to_peer_id : int = -1):
	if !is_multiplayer_authority():
		return
	var data = {
		"round_timer_is_running": !round_timer.is_stopped(),
		"round_timer_time_left": round_timer.time_left,
		"round_count": round_count
	}
	if to_peer_id > -1 and to_peer_id != 1:
		_synchronize.rpc_id(to_peer_id, data)
	else:
		_synchronize.rpc(data)


func get_round_timer_remaining() -> float:
	return round_timer.time_left

func _on_round_timer_timeout():
	if is_multiplayer_authority():
		spawn_interval_timer.stop()
		check_round_completed()

func _begin_round():
	round_count += 1
	round_timer.wait_time = ROUND_BASE_TIME + (ROUND_GROWTH * (round_count - 1))
	round_timer.start()
	
	spawn_interval_timer.wait_time = BASE_ENEMY_SPAWN_TIME + ((round_count -1) * ENEMY_SPAWN_TIME_GROWTH)
	spawn_interval_timer.start()
	synchronize()
	
func check_round_completed():
	if !round_timer.is_stopped():
		return
	
	if round_count >= MAX_WAVE:
		game_complete()
	
	if spawned_enemies == 0:
		round_completed.emit()
		_begin_round()

func game_complete():
	await get_tree().create_timer(2).timeout
	game_completed.emit()

func _on_spawn_interval_timer_timeout():
	if is_multiplayer_authority():
		spawn_enemy()
		spawn_interval_timer.start()

func get_random_spawn_position() -> Vector2:
	var x = randf_range(0, spawn_rect.size.x)
	var y = randf_range(0, spawn_rect.size.y)
	return spawn_rect.global_position + Vector2(x,y)
	
func spawn_enemy():
	var enemy = enemy_scene.instantiate() as Node2D
	enemy.global_position = get_random_spawn_position()
	enemy_spawn_root.add_child(enemy, true)
	spawned_enemies +=1

func _on_enemy_died():
	spawned_enemies -= 1
	check_round_completed()
