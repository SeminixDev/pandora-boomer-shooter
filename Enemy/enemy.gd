extends CharacterBody3D

@export var max_health: int = 30
var current_health: int

func _ready() -> void:
	current_health = max_health

func take_damage(amount: int) -> void:
	current_health -= amount
	print_debug("Enemy took damage! Current Health: ", current_health)
	
	if current_health <= 0:
		die()

func die() -> void:
	print_debug("Enemy destroyed!")
	queue_free()
