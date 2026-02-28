class_name Player extends CharacterBody3D

@export_group("Movement")
@export var speed = 5.0
@export var jump_velocity = 4.5
@export var turn_speed = 0.07

@export_group("Stats")
@export var max_health: int = 100
var current_health: int = max_health

@export_group("Melee (Scythe)")
@export var melee_damage: int = 20
@export var melee_cooldown: float = 0.6
var time_since_last_melee: float = 0.0

@export_group("Dependencies")
@export var bullet_scene: PackedScene
@onready var muzzle: Marker3D = %Muzzle
@onready var melee_ray: RayCast3D = %MeleeRayCast
@onready var animation_player: AnimationPlayer = %AnimationPlayer

# --- Node ---

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta
	
	# Jump
	#if Input.is_action_just_pressed("ui_accept") and is_on_floor():
	#	velocity.y = jump_velocity
	
	if Input.is_action_just_pressed("shoot"):
		shoot()
	
	move()

# --- Controls ---

func move() -> void:
	var input_dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)
	if Input.is_action_pressed("ui_left"):
		self.rotate_y(turn_speed)
	if Input.is_action_pressed("ui_right"):
		self.rotate_y(-turn_speed)
	move_and_slide()

func shoot() -> void:
	if not bullet_scene:
		push_warning("Bullet scene is not assigned to the Player!")
		return
	
	# Spawn the bullet
	var bullet: Bullet = bullet_scene.instantiate()
	get_tree().current_scene.add_child(bullet)
	
	# Set bullet transform
	bullet.global_position = muzzle.global_position
	var shoot_direction = -muzzle.global_transform.basis.z.normalized()
	bullet.set_direction(shoot_direction)
	
	# Bullet settings
	bullet.set_color(Color.GREEN_YELLOW)
	bullet.collision_mask = bullet.collision_mask - 2 # remove player from collision mask

func melee() -> void:
	if time_since_last_melee < melee_cooldown:
		return
		
	time_since_last_melee = 0.0
	
	# Play the scythe/sword swing animation
	if animation_player:
		animation_player.play("melee_swing")
		
	# Check if the raycast is hitting an enemy
	if melee_ray and melee_ray.is_colliding():
		var target = melee_ray.get_collider()
		if target.has_method("take_damage"):
			target.take_damage(melee_damage)

func take_damage(amount: int) -> void:
	current_health -= amount
	print_debug("Player took damage. Current Health: ", current_health)
	
	if current_health <= 0:
		die()

func die() -> void:
	print_debug("Player died! Restarting level...")
	get_tree().reload_current_scene()
