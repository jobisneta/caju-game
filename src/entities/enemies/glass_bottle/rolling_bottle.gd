class_name RollingBottle
extends CharacterBody2D

## RollingBottle hazard obstacle for Home 2.
## Falls from the shelf to the floor, rolls to the right across the room,
## inflicts damage to players upon contact, and breaks against the right wall.

signal broken

enum BottleState { FALLING, ROLLING, BREAKING }

@export var roll_speed: float = 110.0
@export var gravity: float = 500.0
@export var damage: int = 1
@export var max_x_position: float = 640.0

var current_state: BottleState = BottleState.FALLING
var _is_breaking: bool = false

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var hitbox: Area2D = $Hitbox
@onready var hitbox_collision: CollisionShape2D = $Hitbox/CollisionShape2D

func _ready() -> void:
	collision_layer = 16 # Layer 5: hazards
	collision_mask = 1   # Layer 1: world (floor, walls)
	
	if hitbox and not hitbox.body_entered.is_connected(_on_hitbox_body_entered):
		hitbox.body_entered.connect(_on_hitbox_body_entered)

func _physics_process(delta: float) -> void:
	if current_state == BottleState.BREAKING:
		return
		
	match current_state:
		BottleState.FALLING:
			velocity.x = 0.0
			velocity.y += gravity * delta
			move_and_slide()
			
			if is_on_floor():
				current_state = BottleState.ROLLING
				velocity.y = 0.0
				
		BottleState.ROLLING:
			if not is_on_floor():
				velocity.y += gravity * delta
			else:
				velocity.y = 0.0
				
			velocity.x = roll_speed
			move_and_slide()
			
			if sprite:
				sprite.rotation += (roll_speed / 8.0) * delta
				
			if is_on_wall() or global_position.x >= max_x_position:
				break_bottle()

func _on_hitbox_body_entered(body: Node2D) -> void:
	if current_state == BottleState.BREAKING:
		return
	if body and body.is_in_group("player") and body.has_method("take_damage"):
		body.take_damage(damage)

func break_bottle() -> void:
	if _is_breaking:
		return
	_is_breaking = true
	current_state = BottleState.BREAKING
	broken.emit()
	
	# Desativa colisores de forma diferida
	if collision_shape:
		collision_shape.set_deferred("disabled", true)
	if hitbox_collision:
		hitbox_collision.set_deferred("disabled", true)
		
	# Efeito visual de quebra
	if is_inside_tree():
		var tween = create_tween()
		if tween and sprite:
			tween.parallel().tween_property(sprite, "scale", Vector2(1.5, 0.3), 0.08)
			tween.parallel().tween_property(sprite, "modulate:a", 0.0, 0.12)
			tween.tween_callback(queue_free)
			return
			
	queue_free()
