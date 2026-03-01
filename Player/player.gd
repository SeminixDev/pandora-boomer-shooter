class_name Player extends CharacterBody3D

enum State { NORMAL, QUICK_ATTACK, HEAVY_LEAP, HEAVY_SLAM, HEAVY_SLAM_RECOVERY }
var current_state: State = State.NORMAL

@export_group("Movement")
@export var speed : float = 10.0
@export var acceleration : float = 100.0
@export var friction : float = 100.0
@export var turn_speed : float = 2.0 # Radians per second

@export_subgroup("Attack Movement Tuning")
@export var quick_lunge_force: float = 20.0
@export var heavy_leap_upward_force: float = 15.0
@export var heavy_leap_forward_force: float = 5.0
@export var heavy_slam_downward_force: float = 40.0
@export var heavy_slam_speed_multiplier: float = 1.5
@export var heavy_slam_camera_angle: float = -40.0
@export var camera_tilt_speed: float = 100.0

@export_group("Stats")
@export var max_health: int = 100
var current_health: int = max_health

@export_group("Melee Attack")
@export var melee_damage: int = 100
@export var quick_melee_cooldown: float = 0.6
@export var heavy_melee_cooldown: float = 5.0
@export var heavy_charge_time: float = 0.3 # Time holding button to trigger heavy
var time_since_last_quick: float = 0.0
var time_since_last_heavy: float = 0.0
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

@onready var shoot_sound: AudioStreamPlayer3D = %ShootSound

func _ready() -> void:
	current_health = max_health
	
	time_since_last_heavy = heavy_melee_cooldown
	time_since_last_quick = quick_melee_cooldown
	
	scythe.attack_finished.connect(_on_scythe_attack_finished)
	
	floor_max_angle = deg_to_rad(60.0)
	floor_constant_speed = true
	floor_snap_length = 0.5

func _physics_process(delta: float) -> void:
	if not is_on_floor() and current_state != State.HEAVY_SLAM:
		velocity += get_gravity() * delta
	
	time_since_last_quick += delta
	time_since_last_heavy += delta
	time_since_last_ranged += delta
	
	handle_inputs(delta)
	
	# Execute movement based on state
	match current_state:
		State.NORMAL:
			move(delta)
		State.QUICK_ATTACK:
			move(delta, 0.8) # Move at 30% speed
		State.HEAVY_LEAP:
			move(delta, 0.8) # Slight air control while leaping
			if velocity.y <= 0: # Reached apex of leap
				start_heavy_slam()
		State.HEAVY_SLAM:
			turn(delta, 0.3)
			handle_heavy_slam(delta)
		State.HEAVY_SLAM_RECOVERY:
			# Freeze horizontal movement entirely
			turn(delta, 0.3)
			velocity.x = 0
			velocity.z = 0
			move_and_slide() # Keeps gravity/floor collision active
		
	# Camera tilt logic
	if current_state in [State.HEAVY_LEAP, State.HEAVY_SLAM]:
		# Start tilting down immediately when the leap starts
		camera.rotation_degrees.x = move_toward(camera.rotation_degrees.x, heavy_slam_camera_angle, camera_tilt_speed * delta)
	else:
		# Return to normal for all other states
		camera.rotation_degrees.x = move_toward(camera.rotation_degrees.x, original_camera_rotation_x, camera_tilt_speed * delta)

func handle_inputs(delta: float) -> void:
	if current_state != State.NORMAL:
		return # Lockout attacking/re-triggering while already attacking
		
	if Input.is_action_just_pressed("up2"):
		shoot()
		
	# Tap vs Hold Logic
	if Input.is_action_pressed("down2"):
		melee_hold_timer += delta
		if melee_hold_timer >= heavy_charge_time and time_since_last_heavy >= heavy_melee_cooldown:
			start_heavy_leap()
			melee_hold_timer = 0.0
	
	if Input.is_action_just_released("down2"):
		if melee_hold_timer > 0.0 and melee_hold_timer < heavy_charge_time and time_since_last_quick >= quick_melee_cooldown:
			start_quick_attack()
		melee_hold_timer = 0.0

# --- Movement ---

func turn(delta: float, speed_multiplier: float = 1.0) -> void:
	if Input.is_action_pressed("left2"):
		rotate_y(turn_speed * delta * speed_multiplier)
	if Input.is_action_pressed("right2"):
		rotate_y(-turn_speed * delta * speed_multiplier)

func move(delta: float, speed_multiplier: float = 1.0) -> void:
	turn(delta)
	
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
	shoot_sound.pitch_scale = randf_range(0.9, 1.1)
	shoot_sound.play()
	
	if shots_left <= 0:
		shots_left = max_shots
	shots_left -= 1
	time_since_last_ranged = 0.0
	gun.shoot()
	
	if shots_left <= 0:
		gun.reload()

func take_damage(amount: int) -> void:
	if current_state == State.HEAVY_LEAP or current_state == State.HEAVY_SLAM:
		return
	
	animation_player.play("red_screen_flash")
	current_health -= amount
	print_debug("Player took damage. Current Health: ", current_health)
	
	if current_state == State.NORMAL:
		velocity = Vector3.ZERO
	
	if current_health <= 0:
		die()

func die() -> void:
	print_debug("Player died! Restarting level...")
	get_tree().reload_current_scene()
	
# --- State Actions ---

func _on_scythe_attack_finished() -> void:
	if current_state in [State.QUICK_ATTACK, State.HEAVY_SLAM_RECOVERY]:
		end_attack()

func start_quick_attack() -> void:
	current_state = State.QUICK_ATTACK
	time_since_last_quick = 0.0
	velocity += -transform.basis.z * quick_lunge_force 
	scythe.play_quick_attack()

func start_heavy_leap() -> void:
	current_state = State.HEAVY_LEAP
	time_since_last_heavy = 0.0
	velocity.y += heavy_leap_upward_force
	velocity += -transform.basis.z * heavy_leap_forward_force
	scythe.play_heavy_leap()

func start_heavy_slam() -> void:
	current_state = State.HEAVY_SLAM
	velocity = Vector3.ZERO # Kill momentum before plunging

func handle_heavy_slam(delta: float) -> void:
	# Plunge velocity (Down + Camera Forward/Backward/Strafe control)
	var input_direction := Vector3.ZERO
	if Input.is_action_pressed("up1"): input_direction -= transform.basis.z
	if Input.is_action_pressed("down1"): input_direction += transform.basis.z
	if Input.is_action_pressed("left1"): input_direction -= transform.basis.x
	if Input.is_action_pressed("right1"): input_direction += transform.basis.x
	
	if input_direction.length() > 0:
		input_direction = input_direction.normalized()
	
	var target_vel = input_direction * (speed * heavy_slam_speed_multiplier) 
	velocity.x = move_toward(velocity.x, target_vel.x, acceleration * delta)
	velocity.z = move_toward(velocity.z, target_vel.z, acceleration * delta)
	velocity.y = -heavy_slam_downward_force 
	
	move_and_slide()
	
	if is_on_floor():
		trigger_slam_impact()

func trigger_slam_impact() -> void:
	current_state = State.HEAVY_SLAM_RECOVERY
	velocity = Vector3.ZERO # Instantly kill all momentum
	
	scythe.play_heavy_slam_impact()
	scythe.set_heavy_active(true)
	
	await get_tree().create_timer(0.2).timeout
	scythe.set_heavy_active(false)

func end_attack() -> void:
	current_state = State.NORMAL
