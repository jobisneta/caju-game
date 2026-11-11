class_name GlassBottle
extends Area2D

## GlassBottle hazard obstacle.
## Applies damage to players upon contact.
## Physics layers: Layer 5 (hazards - bit 5 = 16), Mask 2 (player - bit 2 = 2).

@export var damage: int = 1
@export var damage_cooldown: float = 1.0

var _last_damage_time: Dictionary = {}

func _ready() -> void:
	collision_layer = 16 # Layer 5: hazards
	collision_mask = 2   # Layer 2: player
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if body and body.is_in_group("player") and body.has_method("take_damage"):
		var now: float = Time.get_ticks_msec() / 1000.0
		var last_hit: float = _last_damage_time.get(body, -999.0)
		if now - last_hit >= damage_cooldown:
			_last_damage_time[body] = now
			body.take_damage(damage)
