class_name WaveManager extends Node

# Dictionary holding enemy scenes and their budget cost
@export var enemy_pool: Dictionary = {
	"Ghoul": {"scene": preload("res://Enemy/ghoul_enemy.tscn"), "cost": 1},
	"Fiend": {"scene": preload("res://Enemy/fiend_enemy.tscn"), "cost": 2},
	"Leaper": {"scene": preload("res://Enemy/leaper_enemy.tscn"), "cost": 4}
}

@export var initial_budget: int = 15
@export var budget_multiplier: float = 1.15
@export var spawn_interval: float = 0.1
@export var breather_duration: float = 5.0

var score: int = 0
var current_wave: int = 1
var current_budget: int = 0
var total_wave_budget: int = 0
var active_enemies: int = 0
var spawn_timer: Timer
var breather_timer: Timer

@onready var spawn_points: Array[Node] = []
@onready var player: Player = %Player

var started: bool = false

func start() -> void:
	if started:
		return
	started = true
	
	# Find all spawn points in the world (Make sure to group your spawn points under a Node called "SpawnPoints" in world.tscn)
	var spawns_node = get_tree().current_scene.get_node_or_null("SpawnPoints")
	if spawns_node:
		spawn_points = spawns_node.get_children()
	
	spawn_timer = Timer.new()
	spawn_timer.wait_time = spawn_interval
	spawn_timer.autostart = false
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	add_child(spawn_timer)
	
	breather_timer = Timer.new()
	breather_timer.one_shot = true
	breather_timer.timeout.connect(start_wave)
	add_child(breather_timer)
	
	# Delay before first wave
	breather_timer.start(5.0)

func start_wave() -> void:
	print("Starting Wave: ", current_wave)
	total_wave_budget = int(initial_budget * pow(budget_multiplier, current_wave - 1))
	current_budget = total_wave_budget
	spawn_timer.start()

func _on_spawn_timer_timeout() -> void:
	if current_budget <= 0:
		spawn_timer.stop()
		return
		
	# Filter valid (safe) spawn points
	var safe_points = spawn_points.filter(func(sp): return sp.is_safe_to_spawn(player))
	if safe_points.is_empty():
		return # Try again next tick
		
	# Pick a random valid enemy within budget
	var affordable = []
	for key in enemy_pool:
		if enemy_pool[key]["cost"] <= current_budget:
			affordable.append(enemy_pool[key])
			
	if affordable.is_empty():
		current_budget = 0 # Can't afford anything else
		return
		
	var chosen_enemy = affordable.pick_random()
	var spawn_point = safe_points.pick_random()
	
	# Spend budget and spawn
	current_budget -= chosen_enemy["cost"]
	active_enemies += 1
	spawn_point.spawn(chosen_enemy["scene"])
	

func _on_enemy_died(enemy_node) -> void:
	active_enemies -= 1
	
	var killed_cost: int = 0
	if enemy_node is GhoulEnemy: killed_cost = 1
	if enemy_node is FiendEnemy: killed_cost = 2
	if enemy_node is LeaperEnemy: killed_cost = 4
	
	score += killed_cost
	check_wave_complete()

func check_wave_complete() -> void:
	if current_budget <= 0 and active_enemies <= 0:
		print("Wave ", current_wave, " Complete!")
		current_wave += 1
		breather_timer.start(breather_duration) # Replaced the await logic

# --- Helpers for the HUD ---
func is_in_breather() -> bool:
	if not breather_timer: return true
	return not breather_timer.is_stopped()

func get_time_until_next_wave() -> float:
	if not breather_timer: return 0.0
	return breather_timer.time_left
