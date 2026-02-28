class_name Scythe extends Node3D

signal attack_finished

@export var quick_damage: int = 20
@export var heavy_damage: int = 40

@onready var primary_hitbox: Area3D = %PrimaryHitbox
@onready var heavy_hitbox: Area3D = %HeavyHitbox
@onready var animation_player: AnimationPlayer = %ScytheAnimationPlayer

func _ready() -> void:
	# Ensure hitboxes are off by default
	set_quick_active(false)
	set_heavy_active(false)

# --- Animation Triggers called by Player ---

func play_quick_attack() -> void:
	animation_player.play("melee_swing")

func play_heavy_leap() -> void:
	animation_player.play("heavy_leap")

func play_heavy_slam_impact() -> void:
	animation_player.play("heavy_slam_impact")

# --- Called by AnimationPlayer Call Method Tracks ---

func set_quick_active(active: bool) -> void:
	primary_hitbox.monitoring = active

func set_heavy_active(active: bool) -> void:
	heavy_hitbox.monitoring = active

func finish_attack() -> void:
	# Called at the very end of the melee_swing and heavy_slam animations!
	attack_finished.emit()

func _on_primary_hitbox_body_entered(body: Node3D) -> void:
	if body.has_method("apply_hit") and body != owner:
		# Small pushback, tiny stun
		var knockback = global_transform.basis.z * 20.0 
		body.apply_hit(quick_damage, knockback, 0.4)

func _on_heavy_hitbox_body_entered(body: Node3D) -> void:
	if body.has_method("apply_hit") and body != owner:
		# Launch into the air (Y-axis) + push away from impact center
		var push_dir = (body.global_position - global_position)
		push_dir.y = 0.0
		push_dir = push_dir.normalized()
		
		var knockback = (push_dir * 10.0) + (Vector3.UP * 15.0) 
		body.apply_hit(heavy_damage, knockback, 2.5) # Stunned for 2.5s
