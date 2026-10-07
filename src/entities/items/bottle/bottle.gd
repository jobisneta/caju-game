class_name Bottle
extends Area2D

## Collectible Bottle for Caju Game.
## Compatible with any character in the 'player' group.
## Notifies GameManager and EventBus on collection.

const PlayerClass = preload("res://src/entities/player/player.gd")

func _ready() -> void:
	# Layer 4 (collectibles = 8), checking Layer 2 (player = 2)
	collision_layer = 8
	collision_mask = 2
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") or body is PlayerClass or body.name.begins_with("Caju"):
		if has_node("/root/GameManager"):
			get_node("/root/GameManager").collect_bottle(body as CharacterBody2D)
		queue_free()
