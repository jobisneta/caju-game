class_name GlassBottle
extends Area2D

## GlassBottle obstacle decorativo na estante.
## Garrafas paradas não causam dano ao jogador.

@export var damage: int = 0
@export var damage_cooldown: float = 1.0

func _ready() -> void:
	collision_layer = 16 # Layer 5: hazards
	collision_mask = 2   # Layer 2: player
	monitoring = false
	monitorable = false

func _on_body_entered(_body: Node2D) -> void:
	# Garrafas paradas não devem dar dano
	pass
