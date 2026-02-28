extends CharacterBody3D

@export_group("Stats")
@export var max_health: int = 30
var current_health: int = max_health

@export_group("Movement")
@export var speed: float = 3.5
@export var acceleration: float = 50.0
@export var friction: float = 50.0

@export_group("Attack")
@export var is_ranged: bool = false
@export var attack_damage: int = 10
@export var attack_range: float = 2.0
@export var attack_cooldown: float = 1.0
var time_since_last_attack: float = 0.0

@export_group("Dependencies")
@export var bullet_scene: PackedScene
@onready var aggro_area: Area3D = %AggroArea
@onready var animation_player: AnimationPlayer = %AnimationPlayer
@onready var sword_aim: Node3D = %MeleeAim
@onready var bullet_spawn_marker: Marker3D = %BulletSpawnMarker
var target: Node3D = null

# State
var is_stunned: bool = false
var stun_timer: float = 0.0

# --- Common ---

func _ready() -> void:
	current_health = max_health

func _physics_process(delta: float) -> void:
	# Add gravity
	if not is_on_floor():
		velocity += get_gravity() * delta
	
	if is_stunned:
		stun_timer -= delta
		if stun_timer <= 0:
			is_stunned = false
		
		# Still process movement so they fall and get knocked back, but skip AI logic
		move_and_slide()
		return
	
	# Increment attack timer
	time_since_last_attack += delta
	
	# Move toward target if exists
	if target:
		move_toward_target(delta)

# --- Movement --- 

func move_toward_target(delta: float) -> void:
	var distance_to_target = global_position.distance_to(target.global_position)
	var ai_direction := Vector3.ZERO
	
	# If out of range, move towards the player
	if distance_to_target > attack_range:
		# Get the vector pointing at the player
		ai_direction = global_position.direction_to(target.global_position)
		ai_direction.y = 0 # Keep it strictly horizontal
		ai_direction = ai_direction.normalized()
		
		# Handle Facing (Look at the player)
		var look_target = target.global_position
		look_target.y = global_position.y
		if global_position.distance_to(look_target) > 0.1:
			look_at(look_target, Vector3.UP)
		var direction = global_position.direction_to(target.global_position)
	
	#  Apply movement physics
	if ai_direction != Vector3.ZERO:
		# Accelerate toward the player
		var target_velocity = ai_direction * speed
		velocity.x = move_toward(velocity.x, target_velocity.x, acceleration * delta)
		velocity.z = move_toward(velocity.z, target_velocity.z, acceleration * delta)
	else:
		# Snappy Stop (In range or lost target)
		# Use friction for a slight slide, or set to 0 for an instant halt
		velocity.x = move_toward(velocity.x, 0, friction * delta)
		velocity.z = move_toward(velocity.z, 0, friction * delta)
		
		# Attack Logic (Only triggers when stopped/in range)
		if distance_to_target <= attack_range:
			handle_attack_logic()
	
	# Return if player killed & scene was reloaded
	if not is_inside_tree():
		return
	
	move_and_slide()

# --- Attacking ---

func handle_attack_logic():
	if time_since_last_attack >= attack_cooldown:
		if is_ranged:
			ranged_attack()
		else:
			melee_attack()
		time_since_last_attack = 0

func melee_attack() -> void:
	# Rotate the sword arm specifically to point exactly at the player's core
	if is_instance_valid(target) and is_instance_valid(sword_aim):
		var aim_position = target.global_position
		aim_position.y = sword_aim.global_position.y
		if sword_aim.global_position.distance_squared_to(aim_position) > 0.001:
			sword_aim.look_at(aim_position, Vector3.UP)
	
	if target is Player:
		target.take_damage(attack_damage)
		time_since_last_attack = 0.0
		print_debug("Enemy attacked player. Player took ", attack_damage, " damage.")
	
	if animation_player:
		animation_player.play("attack_swing")
	
func ranged_attack() -> void:
	if bullet_scene and is_instance_valid(target):
		time_since_last_attack = 0.0
		
		# Fallback spawn position is chest height if no marker exists
		var spawn_pos = global_position + Vector3(0, 1.0, 0)
		if bullet_spawn_marker:
			spawn_pos = bullet_spawn_marker.global_position
		
		var bullet = bullet_scene.instantiate()

		get_tree().current_scene.add_child(bullet)
		
		bullet.set_color(Color.ORANGE_RED)
		
		bullet.global_position = spawn_pos
		var aim_target = target.global_position + Vector3(0, 1.0, 0)
		var shoot_dir = spawn_pos.direction_to(aim_target)
		bullet.set_direction(shoot_dir)
		
		#print_debug("Enemy fired a projectile!")

# --- Damage & Status ---

# Wrapper for normal damage without knockback/stun
func take_damage(amount: int) -> void:
	apply_hit(amount, Vector3.ZERO, 0.0)

# New advanced hit function
func apply_hit(amount: int, knockback: Vector3, stun_duration: float) -> void:
	current_health -= amount
	
	if stun_duration > 0:
		is_stunned = true
		stun_timer = stun_duration
	
	if knockback != Vector3.ZERO:
		velocity += knockback
	
	if current_health <= 0:
		die()

func die() -> void:
	print_debug("Enemy destroyed!")
	queue_free()
	
# --- Targetting  ---

func _on_aggro_area_body_entered(body: Node3D) -> void:
	if body is Player:
		target = body
		#print_debug("Enemy spotted the player")

func _on_aggro_area_body_exited(body: Node3D) -> void:
	if body == target:
		target = null
		#print_debug("Player escaped the enemy's range")
