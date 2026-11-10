class_name PushableBox
extends CharacterBody2D

## Pushable box / crate for Caju Game.
## Acts as a solid obstacle, platform, and affected by gravity.
## Only characters with `can_push_crates = true` (e.g. Tody) can push it.

@export var gravity: float = 600.0

func _ready() -> void:
	add_to_group("pushable")

func _physics_process(delta: float) -> void:
	# Aplica gravidade vertical se não estiver no chão
	if not is_on_floor():
		var g: float = get_gravity().y
		if g == 0.0:
			g = gravity
		velocity.y += g * delta
	else:
		velocity.y = 0.0
	
	velocity.x = 0.0
	move_and_slide()

func push(direction: Vector2, speed: float, delta: float) -> bool:
	var motion = Vector2(direction.x * speed * delta, 0.0)
	var collision = move_and_collide(motion)
	return collision == null or abs(collision.get_normal().x) < 0.5
