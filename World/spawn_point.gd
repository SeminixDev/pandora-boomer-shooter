class_name SpawnPoint extends Marker3D

var safe_distance: float = 40.0 # Won't spawn if player is closer than this
@onready var particles: GPUParticles3D = $GPUParticles3D

func is_safe_to_spawn(player: Node3D) -> bool:
	if not player: return true
	return global_position.distance_to(player.global_position) >= safe_distance

func spawn(enemy_scene: PackedScene) -> void:
	# Trigger visual warning
	particles.restart()
	
	# Wait for particles to look cool before popping the enemy in
	await get_tree().create_timer(1.0).timeout
	
	var enemy: BaseEnemy = enemy_scene.instantiate()
	get_tree().current_scene.get_node("Enemies").add_child(enemy)
	enemy.global_position = global_position
	
	# Notify WaveManager that a new enemy arrived
	var wave_manager = %WaveManager
	if wave_manager:
		enemy.enemy_died.connect(wave_manager._on_enemy_died)
