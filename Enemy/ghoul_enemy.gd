class_name GhoulEnemy extends BaseEnemy

@export_group("Ghoul Attack")
@export var attack_range: float = 3.5
@export var attack_damage: int = 15
@export var attack_cooldown: float = 1.5

@onready var attack_hitbox: Area3D = %AttackHitbox
@onready var animation_player: AnimationPlayer = %AnimationPlayer
var time_since_last_attack: float = 0.0

func _ready() -> void:
	super._ready()
	attack_hitbox.monitoring = false
	attack_hitbox.body_entered.connect(_on_attack_hitbox_body_entered)

func _process_behavior(delta: float) -> void:
	time_since_last_attack += delta
	
	var dist: float = 0.0
	if target: 
		dist = global_position.distance_to(target.global_position)
	
	match current_state:
		State.IDLE:
			if target:
				current_state = State.CHASE
			
		State.CHASE:
			if not target:
				current_state = State.IDLE
				return
				
			face_target(delta)
			
			if dist <= attack_range:
				if time_since_last_attack >= attack_cooldown:
					start_attack()
				else:
					pass
			else:
				var dir = global_position.direction_to(target.global_position)
				dir.y = 0
				velocity.x = move_toward(velocity.x, dir.x * speed, acceleration * delta)
				velocity.z = move_toward(velocity.z, dir.z * speed, acceleration * delta)

		State.ATTACK:
			# Stop moving while attacking
			velocity.x = move_toward(velocity.x, 0, friction * delta)
			velocity.z = move_toward(velocity.z, 0, friction * delta)

func start_attack() -> void:
	current_state = State.ATTACK
	time_since_last_attack = 0.0
	animation_player.play("melee_swing")

# --- Animation Callbacks ---
func set_hitbox_active(active: bool) -> void:
	attack_hitbox.monitoring = active

func finish_attack() -> void:
	current_state = State.CHASE
	set_hitbox_active(false)

func _on_attack_hitbox_body_entered(body: Node3D) -> void:
	if body.has_method("take_damage") and body is Player:
		attack_hitbox.set_deferred("monitoring", false)
		body.take_damage(attack_damage)
		
