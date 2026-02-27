class_name Player extends CharacterBody3D

@export_group("Movement")

@export var speed = 5.0
@export var jump_velocity = 4.5
@export var turn_speed = 0.07

@export_group("Dependencies")

@export var bullet_scene: PackedScene
@onready var muzzle: Marker3D = %BulletSpawnMarker

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
	
	# Set bullet transform up
	bullet.global_position = muzzle.global_position
	var shoot_direction = -muzzle.global_transform.basis.z.normalized()
	bullet.set_direction(shoot_direction)
	
