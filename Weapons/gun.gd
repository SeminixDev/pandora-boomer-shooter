class_name Gun extends Node3D

@export var bullet_scene: PackedScene
@onready var muzzle: Marker3D = %Muzzle
@onready var animation_player: AnimationPlayer = %GunAnimationPlayer

func shoot() -> void:
	if not bullet_scene:
		push_warning("Bullet not assigned to Gun!")
		return
	
	animation_player.play("shoot")
	var bullet: Bullet = bullet_scene.instantiate()
	get_tree().current_scene.add_child(bullet)
	
	# Set bullet transform
	bullet.global_position = muzzle.global_position
	var shoot_direction = -muzzle.global_transform.basis.z.normalized()
	bullet.set_direction(shoot_direction)

func reload() -> void:
	await animation_player.animation_finished
	animation_player.play("reload")
