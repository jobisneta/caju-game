class_name FloorWater
extends CharacterBody2D

## FloorWater hazard obstacle for Caju Game (Home 3).
## Deals damage to players on contact and repeats damage if the player
## remains in contact after temporary invulnerability expires.

@export var damage: int = 1

@onready var hitbox: Area2D = $Hitbox

func _ready() -> void:
	# Desativa colisão física sólida para não criar degrau no chão
	collision_layer = 0
	collision_mask = 0
	
	if hitbox:
		hitbox.collision_layer = 16 # Layer 5: hazards
		hitbox.collision_mask = 2   # Layer 2: player
		if not hitbox.body_entered.is_connected(_on_hitbox_body_entered):
			hitbox.body_entered.connect(_on_hitbox_body_entered)

func _physics_process(_delta: float) -> void:
	if not hitbox or not hitbox.monitoring:
		return
	for body in hitbox.get_overlapping_bodies():
		_try_damage_body(body)

func _on_hitbox_body_entered(body: Node2D) -> void:
	_try_damage_body(body)

func _try_damage_body(body: Node2D) -> void:
	if not body or not body.is_in_group("player"):
		return
	if "is_invulnerable" in body and body.is_invulnerable:
		return
	if body.has_method("take_damage"):
		body.take_damage(damage)
