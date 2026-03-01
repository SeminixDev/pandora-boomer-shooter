class_name Gun extends Node3D

@export var bullet_scene: PackedScene

# Shotgun parameters
@export_group("Shotgun")
@export var pellets_per_shot: int = 8
@export var spread_angle_deg: float = 8.0 # cone half-angle in degrees
@export var pellet_speed_multiplier: float = 2.0
@export var randomize_spread: bool = true # if false tries to use deterministic spread (simple grid)

@onready var muzzle: Marker3D = %Muzzle
@onready var animation_player: AnimationPlayer = %GunAnimationPlayer

func _ready() -> void:
	# Seed random
	randomize()

func shoot() -> void:
	if not bullet_scene:
		push_warning("Bullet not assigned to Gun!")
		return
	
	animation_player.play("shoot")
	
	# Base shoot direction (gun forward is -Z)
	var base_dir: Vector3 = -muzzle.global_transform.basis.z.normalized()
	var angle_rad: float = deg_to_rad(spread_angle_deg)
	
	# Spawn pellets
	for i in range(pellets_per_shot):
		var bullet: Bullet = bullet_scene.instantiate()
		get_tree().current_scene.add_child(bullet)
		bullet.global_position = muzzle.global_position
		
		var dir: Vector3 = base_dir
		if pellets_per_shot > 1:
			if randomize_spread:
				dir = _random_dir_in_cone(base_dir, angle_rad)
			else:
				# Simple deterministic horizontal fan spread
				# evenly distribute pellets across [-spread, +spread] horizontally
				var t = 0.0
				if pellets_per_shot > 1:
					t = float(i) / float(pellets_per_shot - 1) # 0..1
					var yaw = lerp(-angle_rad, angle_rad, t)
					dir = _rotate_vector_around_axis(base_dir, Vector3.UP, yaw)
		
		bullet.speed *= pellet_speed_multiplier
		bullet.set_direction(dir)

func reload() -> void:
	await animation_player.animation_finished
	animation_player.play("reload")


# ---- Helpers ----

func _random_dir_in_cone(base_dir: Vector3, angle_rad: float) -> Vector3:
	# Sample a direction uniformly inside a cone (solid-angle uniform)
	# cos(theta) is uniform between cos(angle) and 1
	var cos_a = cos(angle_rad)
	var cos_theta = randf_range(cos_a, 1.0)
	var sin_theta = sqrt(max(0.0, 1.0 - cos_theta * cos_theta))
	var phi = randf() * TAU
	var local_x = cos(phi) * sin_theta
	var local_y = sin(phi) * sin_theta
	var local_z = cos_theta
	
	# Build orthonormal basis with base_dir as the "forward" (z) axis
	var forward = base_dir.normalized()
	var right = forward.cross(Vector3.UP)
	if right.length() < 0.001:
		# forward is nearly parallel to UP; pick another up
		right = forward.cross(Vector3.FORWARD)
	right = right.normalized()
	var up = right.cross(forward).normalized()
	
	# Convert local spherical to world
	return (right * local_x) + (up * local_y) + (forward * local_z)

func _rotate_vector_around_axis(vec: Vector3, axis: Vector3, angle: float) -> Vector3:
	# Rotate vec around axis (world-space) by angle radians
	var q = Quaternion(axis.normalized(), angle)
	return q.xform(vec)
