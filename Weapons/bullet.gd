class_name Bullet extends Area3D

@export var speed: float = 40.0
@export var damage: int = 10
@export var lifetime: float = 4.0

@export_group("Damage Targets")
@export var damage_player: bool = true
@export var damage_enemy: bool = true

var direction: Vector3 = Vector3.ZERO

@onready var mesh = %MeshInstance3D

func _ready() -> void:
	# Connect the collision signal
	body_entered.connect(_on_body_entered)
	
	# Destroy the bullet after lifetime seconds
	await get_tree().create_timer(lifetime).timeout
	queue_free()

func _physics_process(delta: float) -> void:
	# Move the bullet forward based on its local Z axis
	global_position += direction * speed * delta

func _on_body_entered(body: Node3D) -> void:
	# Damage the object if possible
	if body.has_method("take_damage"):
		if body == Player and damage_player:
			body.take_damage(damage)
		if body == BaseEnemy and damage_enemy:
			body.take_damage(damage)
	
	# Destroy the bullet upon hitting anything (enemy, wall, etc.)
	queue_free()

func set_direction(dir: Vector3) -> void:
	direction = dir
	look_at(position + direction, Vector3.UP)

func set_color(color: Color) -> void:
	if not is_node_ready():
		await ready
	
	var mat = mesh.get_active_material(0).duplicate()
	mat.albedo_color = color
	mesh.set_surface_override_material(0, mat)
