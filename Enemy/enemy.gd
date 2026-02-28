extends CharacterBody3D

@export_group("Stats")
@export var speed: float = 3.5
@export var max_health: int = 30
var current_health: int

@export_group("Attack")
@export var attack_damage: int = 10
@export var attack_range: float = 2.0
@export var attack_cooldown: float = 1.0
var time_since_last_attack: float = 0.0

@export_group("Dependencies")
@onready var aggro_area: Area3D = %AggroArea
var target: Node3D = null

# --- Common ---

func _ready() -> void:
	current_health = max_health

func _physics_process(delta: float) -> void:
	# Add gravity
	if not is_on_floor():
		velocity += get_gravity() * delta
	
	# Increment attack timer
	time_since_last_attack += delta
	
	# Move toward target if exists
	if target:
		move_toward_target()
	
	move_and_slide()

# --- Movement --- 
func move_toward_target() -> void:
	var distance_to_target = global_position.distance_to(target.global_position)
	
	# If out of range, move towards the player
	if distance_to_target > attack_range:
		var direction = global_position.direction_to(target.global_position)
		
		# Keep movement horizontal
		direction.y = 0 
		direction = direction.normalized()
		
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
		
		# Look at the player but lock vertical tilt
		var look_target = target.global_position
		look_target.y = global_position.y
		if global_position.distance_to(look_target) > 0.1:
			look_at(look_target, Vector3.UP)
			
	# If in range, stop and attack
	else:
		velocity.x = 0
		velocity.z = 0
		
		if time_since_last_attack >= attack_cooldown:
			attack()

# --- Attacking ---

func attack() -> void:
	if target and target.has_method("take_damage"):
		target.take_damage(attack_damage)
		time_since_last_attack = 0.0
		print_debug("Enemy attacked player. Player took ", attack_damage, " damage.")

# --- Damage ---

func take_damage(amount: int) -> void:
	current_health -= amount
	print_debug("Enemy took damage. Current Health: ", current_health)
	
	if current_health <= 0:
		die()

func die() -> void:
	print_debug("Enemy destroyed!")
	queue_free()
	
# --- Targetting  ---

func _on_aggro_area_body_entered(body: Node3D) -> void:
	if body is Player:
		target = body
		print_debug("Enemy spotted the player")

func _on_aggro_area_body_exited(body: Node3D) -> void:
	if body == target:
		target = null
		print_debug("Player escaped the enemy's range")
