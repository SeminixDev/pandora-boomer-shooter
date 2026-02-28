class_name Gun extends Node3D

@export var bullet_scene: PackedScene
@onready var muzzle: Marker3D = %Muzzle

func shoot() -> void:
	if not bullet_scene:
		push_warning("Bullet not assigned to Gun!")
		return
	
	var bullet: Bullet = bullet_scene.instantiate()
	get_tree().current_scene.add_child(bullet)
	
	# Set bullet transform
	bullet.global_position = muzzle.global_position
	var shoot_direction = -muzzle.global_transform.basis.z.normalized()
	bullet.set_direction(shoot_direction)
	
	# Bullet settings
	bullet.set_color(Color.GREEN_YELLOW)
	bullet.collision_mask = bullet.collision_mask - 2 # remove player from collision mask
