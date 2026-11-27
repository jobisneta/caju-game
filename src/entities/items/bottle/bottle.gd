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
	if not visible:
		set_deferred("monitoring", false)
		var col: CollisionShape2D = get_node_or_null("CollisionShape2D")
		if col:
			col.set_deferred("disabled", true)

func reveal() -> void:
	visible = true
	set_deferred("monitoring", true)
	var col: CollisionShape2D = get_node_or_null("CollisionShape2D")
	if col:
		col.set_deferred("disabled", false)
	if is_inside_tree():
		scale = Vector2(0.4, 0.4)
		var tween: Tween = create_tween()
		if tween:
			tween.tween_property(self, "scale", Vector2.ONE, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _on_body_entered(body: Node2D) -> void:
	if not visible:
		return
	if body.is_in_group("player") or body is PlayerClass or body.name.begins_with("Caju"):
		if has_node("/root/GameManager"):
			get_node("/root/GameManager").collect_bottle(body as CharacterBody2D)
		queue_free()
