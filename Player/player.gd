class_name Player extends CharacterBody3D

enum State { NORMAL, QUICK_ATTACK, HEAVY_LEAP, HEAVY_SLAM }
var current_state: State = State.NORMAL

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
@export var heavy_charge_time: float = 0.3 # Time holding button to trigger heavy
var time_since_last_melee: float = 0.0
var melee_hold_timer: float = 0.0

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
@onready var camera: Camera3D = %MainCamera
var original_camera_rotation_x: float = 0.0

# --- Node ---

func _ready() -> void:
	original_camera_rotation_x = camera.rotation.x

func _physics_process(delta: float) -> void:
	if not is_on_floor() and current_state != State.HEAVY_SLAM:
		velocity += get_gravity() * delta
	
	time_since_last_melee += delta
	time_since_last_ranged += delta
	
	handle_inputs(delta)
	
	# Execute movement based on state
	match current_state:
		State.NORMAL:
			move(delta)
		State.QUICK_ATTACK:
			move(delta, 0.3) # Move at 30% speed
		State.HEAVY_LEAP:
			move(delta, 0.5) # Slight air control while leaping
			if velocity.y <= 0: # Reached apex of leap
				start_heavy_slam()
		State.HEAVY_SLAM:
			handle_heavy_slam(delta)

func handle_inputs(delta: float) -> void:
	if current_state != State.NORMAL:
		return # Lockout attacking/re-triggering while already attacking
		
	if Input.is_action_just_pressed("up2"):
		shoot()
		
	# Tap vs Hold Logic
	if Input.is_action_pressed("down2"):
		melee_hold_timer += delta
		if melee_hold_timer >= heavy_charge_time and time_since_last_melee >= melee_cooldown:
			start_heavy_leap()
			melee_hold_timer = 0.0
	
	if Input.is_action_just_released("down2"):
		if melee_hold_timer > 0.0 and melee_hold_timer < heavy_charge_time and time_since_last_melee >= melee_cooldown:
			start_quick_attack()
		melee_hold_timer = 0.0

# --- Movement ---

func move(delta: float, speed_multiplier: float = 1.0) -> void:
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
		var target_velocity = input_direction * (speed * speed_multiplier)
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
	
# --- State Actions ---

func start_quick_attack() -> void:
	current_state = State.QUICK_ATTACK
	time_since_last_melee = 0.0
	# Slight forward lunge
	velocity += -transform.basis.z * 10.0 
	animation_player.play("melee_swing")
	# Rely on the AnimationPlayer calling `end_attack()` when finished

func start_heavy_leap() -> void:
	current_state = State.HEAVY_LEAP
	time_since_last_melee = 0.0
	# Launch up and slightly forward
	velocity.y = 15.0
	velocity += -transform.basis.z * 5.0
	animation_player.play("heavy_leap") # Play wind-up animation

func start_heavy_slam() -> void:
	current_state = State.HEAVY_SLAM
	velocity = Vector3.ZERO # Kill momentum before plunging

func handle_heavy_slam(delta: float) -> void:
	# Face camera downward
	camera.rotation_degrees.x = move_toward(camera.rotation_degrees.x, -75.0, 300 * delta)
	
	# Plunge velocity (Down + Camera Forward/Backward/Strafe control)
	var input_direction := Vector3.ZERO
	if Input.is_action_pressed("up1"): input_direction -= transform.basis.z
	if Input.is_action_pressed("down1"): input_direction += transform.basis.z
	if Input.is_action_pressed("left1"): input_direction -= transform.basis.x
	if Input.is_action_pressed("right1"): input_direction += transform.basis.x
	
	if input_direction.length() > 0:
		input_direction = input_direction.normalized()
	
	var target_vel = input_direction * (speed * 1.5) # Allow fast air control
	velocity.x = move_toward(velocity.x, target_vel.x, acceleration * delta)
	velocity.z = move_toward(velocity.z, target_vel.z, acceleration * delta)
	velocity.y = -40.0 # Extreme downward force
	
	move_and_slide()
	
	if is_on_floor():
		trigger_slam_impact()

func trigger_slam_impact() -> void:
	# Impact
	camera.rotation.x = original_camera_rotation_x # Reset camera instantly
	animation_player.play("heavy_slam_impact")
	scythe.set_heavy_active(true)
	
	# TODO: Shake screen, spawn particles here in the future
	
	# Disable hitbox and return to normal after brief delay
	await get_tree().create_timer(0.2).timeout
	scythe.set_heavy_active(false)
	end_attack()

func end_attack() -> void:
	current_state = State.NORMAL
