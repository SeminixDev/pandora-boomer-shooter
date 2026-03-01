extends Control

@onready var wave_label: Label = %WaveLabel
@onready var difficulty_label: Label = %DifficultyLabel
@onready var enemies_label: Label = %EnemiesLabel
@onready var timer_label: Label = %TimerLabel
@onready var health_label: Label = %HealthLabel
@onready var heavy_cooldown_bar: ProgressBar = %HeavyCooldownBar

var player: Player
var wave_manager: WaveManager

func _ready() -> void:
	# Wait for the scene tree to settle to grab references
	await get_tree().process_frame
	player = get_tree().current_scene.get_node_or_null("%Player")
	wave_manager = get_tree().current_scene.get_node_or_null("%WaveManager")
	
	if not player:
		push_warning("HUD could not find %Player")
	if not wave_manager:
		push_warning("HUD could not find %WaveManager")

func _process(_delta: float) -> void:
	update_player_stats()
	update_wave_stats()

func update_player_stats() -> void:
	if not player: return
	
	# Health
	health_label.text = "Health: %d / %d" % [player.current_health, player.max_health]
	
	# Heavy Attack Cooldown
	var cooldown_ratio = clamp(player.time_since_last_heavy / player.heavy_melee_cooldown, 0.0, 1.0)
	heavy_cooldown_bar.value = cooldown_ratio * 100.0
	
	# Change color to green when ready, gray/red when charging
	if cooldown_ratio >= 1.0:
		heavy_cooldown_bar.modulate = Color(0.2, 1.0, 0.2) # Bright Green
	else:
		heavy_cooldown_bar.modulate = Color(0.5, 0.5, 0.5) # Gray out

func update_wave_stats() -> void:
	if not wave_manager: return
	
	wave_label.text = "Wave: %d" % wave_manager.current_wave
	difficulty_label.text = "Difficulty Score: %d" % wave_manager.total_wave_budget
	
	# Indicate remaining enemies + if there's remaining budget that will spawn
	if wave_manager.current_budget > 0:
		enemies_label.text = "Active Enemies: %d (More spawning...)" % wave_manager.active_enemies
	else:
		enemies_label.text = "Enemies Remaining: %d" % wave_manager.active_enemies
		
	# Timer display
	if wave_manager.is_in_breather():
		timer_label.visible = true
		timer_label.text = "Next Wave in: %.1f s" % wave_manager.get_time_until_next_wave()
		enemies_label.visible = false
	else:
		timer_label.visible = false
		enemies_label.visible = true
