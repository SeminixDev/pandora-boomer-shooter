class_name BaseEnemy extends CharacterBody3D

enum State { IDLE, CHASE, ATTACK, STUNNED, RUN }
var current_state: State = State.IDLE

@export_group("Stats")
@export var max_health: int = 30
var current_health: int = max_health

@export_group("Movement")
@export var speed: float = 3.5
@export var acceleration: float = 50.0
@export var friction: float = 50.0

@export_group("Dependencies")
@onready var aggro_area: Area3D = %AggroArea
@onready var hurt_sound: AudioStreamPlayer3D = %HurtSound
@onready var attack_sound: AudioStreamPlayer3D = %AttackSound
@onready var death_sound: AudioStreamPlayer3D = %DeathSound
var target: Node3D = null

var is_dead: bool = false

# State Variables
var stun_timer: float = 0.0

signal enemy_died(enemy_node)

func _ready() -> void:
	current_health = max_health
	
	floor_max_angle = deg_to_rad(60.0)
	floor_constant_speed = true
	floor_snap_length = 0.5

func _physics_process(delta: float) -> void:
	# Add gravity
	if not is_on_floor():
		velocity += get_gravity() * delta
	
	if current_state == State.STUNNED:
		handle_stun_state(delta)
		return
		
	# Execute derived behavior
	_process_behavior(delta)
	
	# Fallback friction if behavior didn't set velocity
	if current_state == State.IDLE:
		velocity.x = move_toward(velocity.x, 0, friction * delta)
		velocity.z = move_toward(velocity.z, 0, friction * delta)
		
	move_and_slide()

# Virtual function for derived enemies to override
func _process_behavior(_delta: float) -> void:
	pass

# Helper function for derived enemies to face the player
func face_target(delta: float, turn_speed: float = 10.0) -> void:
	if not target: return
	var look_target = target.global_position
	look_target.y = global_position.y
	if global_position.distance_to(look_target) > 0.1:
		var target_transform = transform.looking_at(look_target, Vector3.UP)
		transform = transform.interpolate_with(target_transform, turn_speed * delta)

# --- Damage & Status ---

func take_damage(amount: int) -> void:
	apply_hit(amount, Vector3.ZERO, 0.0)

func apply_hit(amount: int, knockback: Vector3, stun_duration: float) -> void:
	current_health -= amount
	
	hurt_sound.pitch_scale = randf_range(0.8, 1.2)
	hurt_sound.play()
	
	if stun_duration > 0:
		current_state = State.STUNNED
		stun_timer = stun_duration
	
	if knockback != Vector3.ZERO:
		velocity += knockback
	
	if current_health <= 0:
		die()

func handle_stun_state(delta: float) -> void:
	stun_timer -= delta
	if stun_timer <= 0:
		current_state = State.IDLE
	
	if is_on_floor():
		velocity.x = move_toward(velocity.x, 0, friction * delta)
		velocity.z = move_toward(velocity.z, 0, friction * delta)
	move_and_slide()

func die() -> void:
	if is_dead: return
	is_dead = true
	enemy_died.emit(self)
	
	death_sound.reparent(get_parent())
	death_sound.pitch_scale = randf_range(0.8, 1.2)
	death_sound.play()
	
	queue_free()

# --- Targetting  ---

func _on_aggro_area_body_entered(body: Node3D) -> void:
	if body is Player:
		target = body

func _on_aggro_area_body_exited(body: Node3D) -> void:
	if body == target:
		target = null
