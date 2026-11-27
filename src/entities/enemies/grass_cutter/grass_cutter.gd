class_name GrassCutter
extends CharacterBody2D

## GrassCutter patrolling enemy for Garden level (garden_1.tscn).
## Patrols horizontally between Plataforma7 and Plataforma10, flipping horizontally
## on wall collision, and deals 1 shared damage to players on contact.

@export var move_speed: float = 90.0
@export var gravity: float = 500.0
@export var damage: int = 1
@export var start_direction: float = 1.0

var direction: float = 1.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var hitbox: Area2D = $Hitbox

func _ready() -> void:
	collision_layer = 16 # Layer 5: hazards
	collision_mask = 1   # Layer 1: world (floor, Plataforma7, Plataforma10)
	direction = 1.0 if start_direction >= 0.0 else -1.0
	_update_sprite_flip()
	
	if hitbox:
		hitbox.collision_layer = 16 # Layer 5: hazards
		hitbox.collision_mask = 2   # Layer 2: player
		if not hitbox.body_entered.is_connected(_on_hitbox_body_entered):
			hitbox.body_entered.connect(_on_hitbox_body_entered)

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		velocity.y = 0.0
		
	velocity.x = move_speed * direction
	move_and_slide()
	
	if is_on_wall():
		flip_direction()
		
	if hitbox and hitbox.monitoring:
		for body in hitbox.get_overlapping_bodies():
			_try_damage_body(body)

func flip_direction() -> void:
	direction = -direction
	_update_sprite_flip()

func _update_sprite_flip() -> void:
	if sprite:
		sprite.flip_h = (direction < 0.0)

func _on_hitbox_body_entered(body: Node2D) -> void:
	_try_damage_body(body)

func _try_damage_body(body: Node2D) -> void:
	if not body or not body.is_in_group("player"):
		return
	if "is_invulnerable" in body and body.is_invulnerable:
		return
	if body.has_method("take_damage"):
		body.take_damage(damage)
