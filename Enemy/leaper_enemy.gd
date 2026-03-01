class_name LeaperEnemy extends BaseEnemy

@export_group("Leaper Combat")
@export var leap_range: float = 30.0
@export var leap_force: float = 20.0
@export var leap_damage: int = 25
@export var telegraph_duration: float = 0.7
@export var attack_cooldown: float = 4.0

@onready var lunge_hitbox: Area3D = %LungeHitbox
var time_since_last_attack: float = 0.0
var lunge_direction: Vector3 = Vector3.ZERO

func _ready() -> void:
	super._ready()
	lunge_hitbox.monitoring = false
	lunge_hitbox.body_entered.connect(_on_lunge_hitbox_body_entered)

func _process_behavior(delta: float) -> void:
	time_since_last_attack += delta
	
	match current_state:
		State.IDLE:
			if target: current_state = State.CHASE
			
		State.CHASE:
			if not target: return
			face_target(delta)
			var dist = global_position.distance_to(target.global_position)
			
			if dist <= leap_range and time_since_last_attack >= attack_cooldown:
				start_telegraph()
			else:
				var dir = global_position.direction_to(target.global_position).normalized()
				velocity.x = move_toward(velocity.x, dir.x * speed, acceleration * delta)
				velocity.z = move_toward(velocity.z, dir.z * speed, acceleration * delta)

		State.ATTACK:
			if not lunge_hitbox.monitoring:
				face_target(delta, 15.0) 
			else:
				# Don't turn mid-air.
				if is_on_floor() and velocity.y <= 0:
					finish_attack()

func start_telegraph() -> void:
	current_state = State.ATTACK
	time_since_last_attack = 0.0
	velocity = Vector3.ZERO
	
	# TODO: Play a "crouching" telegraph animation here
	# animation_player.play("telegraph") and emit finished signal
	
	await get_tree().create_timer(telegraph_duration).timeout
	
	if current_state == State.ATTACK and target:
		execute_leap()

func execute_leap() -> void:
	if not target: return
	
	lunge_hitbox.monitoring = true
	
	# Force an instant snap to face the target perfectly before launching
	var look_target = target.global_position
	look_target.y = global_position.y
	look_at(look_target, Vector3.UP)
	
	# Calculate trajectory
	lunge_direction = global_position.direction_to(target.global_position)
	lunge_direction.y = 0.0
	lunge_direction = lunge_direction.normalized()
	
	velocity = lunge_direction * leap_force
	velocity.y = 5.0 # Slight arc upward

func finish_attack() -> void:
	current_state = State.CHASE
	lunge_hitbox.monitoring = false
	
	# Kill the leap momentum instantly so it doesn't slide
	velocity.x = 0.0
	velocity.z = 0.0
	
	time_since_last_attack = 0.0
	
func _on_lunge_hitbox_body_entered(body: Node3D) -> void:
	if body.has_method("take_damage") and body is Player:
		body.take_damage(leap_damage)
