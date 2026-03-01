extends Control

@onready var wave_label: RichTextLabel = %WaveLabel
@onready var score_label: RichTextLabel = %ScoreLabel
@onready var difficulty_label: RichTextLabel = %DifficultyLabel
@onready var enemies_label: RichTextLabel = %EnemiesLabel
@onready var timer_label: RichTextLabel = %TimerLabel
@onready var health_bar: ProgressBar = %HealthBar
@onready var heavy_cooldown_label: RichTextLabel = %HeavyCooldownLabel

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
	
	# --- Health Bar ---
	health_bar.max_value = player.max_health
	health_bar.value = player.current_health
	
	# --- Heavy Attack Cooldown ---
	var is_heavy_ready = player.time_since_last_heavy >= player.heavy_melee_cooldown
	
	if is_heavy_ready:
		heavy_cooldown_label.text = "Heavy Attack: READY"
		heavy_cooldown_label.add_theme_color_override("default_color", Color(0.0, 0.897, 0.059, 1.0)) 
	else:
		heavy_cooldown_label.text = "Heavy Attack: CHARGING..."
		heavy_cooldown_label.add_theme_color_override("default_color", Color(0.376, 0.024, 0.0, 0.404))

func update_wave_stats() -> void:
	if not wave_manager: return
	
	wave_label.text = "Wave: %d" % wave_manager.current_wave
	score_label.text = "Score: %d" % wave_manager.score
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
