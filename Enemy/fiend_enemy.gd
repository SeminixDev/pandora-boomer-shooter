class_name FiendEnemy extends BaseEnemy

@export_group("Fiend Combat")
@export var preferred_range: float = 12.0
@export var stop_range: float = 8.0 # Won't get closer than this
@export var attack_cooldown: float = 2.5
@export var fireball_scene: PackedScene

@onready var spawn_marker: Marker3D = %BulletSpawnMarker
var time_since_last_attack: float = 0.0

func _process_behavior(delta: float) -> void:
	time_since_last_attack += delta
	
	match current_state:
		State.IDLE:
			if target: current_state = State.CHASE
			
		State.CHASE:
			if not target:
				current_state = State.IDLE
				return
				
			face_target(delta)
			var dist = global_position.distance_to(target.global_position)
			
			# Movement Logic
			if dist > preferred_range:
				var dir = global_position.direction_to(target.global_position).normalized()
				velocity.x = move_toward(velocity.x, dir.x * speed, acceleration * delta)
				velocity.z = move_toward(velocity.z, dir.z * speed, acceleration * delta)
			elif dist < stop_range:
				# Back away slowly
				var dir = target.global_position.direction_to(global_position).normalized()
				velocity.x = move_toward(velocity.x, dir.x * (speed * 0.5), acceleration * delta)
				velocity.z = move_toward(velocity.z, dir.z * (speed * 0.5), acceleration * delta)
			else:
				# Stop and hold ground
				velocity.x = move_toward(velocity.x, 0, friction * delta)
				velocity.z = move_toward(velocity.z, 0, friction * delta)

			# Attack Logic
			if time_since_last_attack >= attack_cooldown:
				start_attack()

		State.ATTACK:
			velocity.x = move_toward(velocity.x, 0, friction * delta)
			velocity.z = move_toward(velocity.z, 0, friction * delta)
			face_target(delta)

func start_attack() -> void:
	current_state = State.ATTACK
	time_since_last_attack = 0.0
	
	# If you have a casting animation, play it here and call shoot_fireball() via animation
	# For now, we use a timer as a placeholder for an animation
	await get_tree().create_timer(0.5).timeout 
	if current_state == State.ATTACK: # Ensure not stunned or dead
		shoot_fireball()
		finish_attack()

func shoot_fireball() -> void:
	if not fireball_scene or not target: return
	
	var fireball = fireball_scene.instantiate()
	get_tree().current_scene.add_child(fireball)
	
	fireball.global_position = spawn_marker.global_position
	var aim_target = target.global_position
	aim_target = Vector3(aim_target.x, global_position.y, aim_target.z)
	var shoot_dir = spawn_marker.global_position.direction_to(aim_target)
	fireball.set_direction(shoot_dir)

func finish_attack() -> void:
	current_state = State.CHASE
