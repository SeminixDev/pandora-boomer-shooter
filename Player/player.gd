class_name Player extends CharacterBody3D

@export_group("Movement")
@export var speed : float = 10.0
@export var acceleration : float = 100.0
@export var friction : float = 100.0
@export var turn_speed : float = 3.0 # Radians per second

@export_group("Stats")
@export var max_health: int = 100
var current_health: int = max_health

@export_group("Melee Attack")
@export var melee_damage: int = 20
@export var melee_cooldown: float = 0.6
var time_since_last_melee: float = 0.0

@export_group("Ranged Attack")
@export var ranged_cooldown: float = 0.1
@export var ranged_reload_time: float = 1.0
@export var max_shots: int = 2
var time_since_last_ranged: float = 0.0
var shots_left: int = 2

@export_group("Dependencies")
@onready var gun: Gun = %Gun
@onready var scythe: Scythe = %Scythe
@onready var muzzle: Marker3D = %Muzzle
@onready var animation_player: AnimationPlayer = %AnimationPlayer

# --- Node ---

func _physics_process(delta: float) -> void:
	# Add gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta
	
	move(delta)
	
	time_since_last_melee += delta
	time_since_last_ranged += delta
	
	if Input.is_action_just_pressed("up2"):
		shoot()
	if Input.is_action_just_pressed("down2"):
		melee()


# --- Controls ---

func move(delta: float) -> void:
	# 1. Handle Rotation (Turning)
	if Input.is_action_pressed("left2"):
		rotate_y(turn_speed * delta)
	if Input.is_action_pressed("right2"):
		rotate_y(-turn_speed * delta)

	# Build the Movement Direction
	var input_direction := Vector3.ZERO

	# Forward/Back (Z-axis)
	if Input.is_action_pressed("up1"):
		input_direction -= transform.basis.z
	if Input.is_action_pressed("down1"):
		input_direction += transform.basis.z

	# Strafing (X-axis)
	if Input.is_action_pressed("left1"):
		input_direction -= transform.basis.x
	if Input.is_action_pressed("right1"):
		input_direction += transform.basis.x

	# Normalizing prevents diagonal speed boost
	if input_direction.length() > 0:
		input_direction = input_direction.normalized()

	# Apply Acceleration & Friction
	if input_direction != Vector3.ZERO:
		var target_velocity = input_direction * speed
		velocity.x = move_toward(velocity.x, target_velocity.x, acceleration * delta)
		velocity.z = move_toward(velocity.z, target_velocity.z, acceleration * delta)
	else:
		velocity.x = move_toward(velocity.x, 0, friction * delta)
		velocity.z = move_toward(velocity.z, 0, friction * delta)
	
	# Execute Movement
	move_and_slide()

func shoot() -> void:
	# Handle cooldown & reload
	if shots_left <= 0 and time_since_last_ranged < ranged_reload_time:
		return	
	if time_since_last_ranged < ranged_cooldown:
		return
	
	# Shoot
	if shots_left <= 0:
		shots_left = max_shots
	shots_left -= 1
	time_since_last_ranged = 0.0
	gun.shoot()

func melee() -> void:
	
	# Handle cooldown
	if time_since_last_melee < melee_cooldown:
		return
		
	time_since_last_melee = 0.0
	
	animation_player.play("melee_swing")

func take_damage(amount: int) -> void:
	current_health -= amount
	print_debug("Player took damage. Current Health: ", current_health)
	
	if current_health <= 0:
		die()

func die() -> void:
	print_debug("Player died! Restarting level...")
	get_tree().reload_current_scene()
