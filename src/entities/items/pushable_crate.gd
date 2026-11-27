class_name PushableCrate
extends StaticBody2D

## Interactive Pushable Crate for Caju Game.
## Falls from CaixaPos1 to CaixaPos2 when Caju interacts from the right side.

signal crate_fallen

@export var target_box: StaticBody2D
@export var requires_right_side: bool = true
@export var requires_left_side: bool = false
@export var break_on_land: bool = false
@export var reveal_item: Node2D = null

var _is_fallen: bool = false
var som_tocado: bool = false

func _ready() -> void:
	add_to_group("interactable")
	# Ativa camada 1 (world) e camada 10 (interactables: bit 10 = 512)
	collision_layer = 1 | 512

func can_interact(player: CharacterBody2D) -> bool:
	if _is_fallen:
		return false
	if requires_right_side and player:
		if player.global_position.x <= global_position.x + 4.0:
			return false
	elif requires_left_side and player:
		if player.global_position.x >= global_position.x - 4.0:
			return false
	return true

func interact(player: CharacterBody2D) -> void:
	if not can_interact(player):
		if not _is_fallen and player:
			if requires_right_side and player.global_position.x <= global_position.x + 4.0:
				print("[PushableCrate] O Caju precisa estar à direita da caixa para derrubá-la para a esquerda.")
			elif requires_left_side and player.global_position.x >= global_position.x - 4.0:
				print("[PushableCrate] O Caju precisa estar à esquerda da caixa para derrubá-la para a direita.")
		return
	
	fall_to_target()

func fall_to_target() -> void:
	if _is_fallen:
		return
		
	if not som_tocado and has_node("/root/GameManager"):
		som_tocado = true
		var audio = AudioStreamPlayer.new()
		audio.stream = preload("res://assets/sounds/som_caixa.mp3")
		audio.bus = &"SFX"
		get_node("/root/GameManager").add_child(audio)
		audio.play()
		audio.finished.connect(audio.queue_free)
			
	_is_fallen = true
	
	var col: CollisionShape2D = get_node_or_null("CollisionShape2D")
	if col:
		col.set_deferred("disabled", true)
	
	var target_pos: Vector2 = target_box.global_position if target_box else Vector2(395, 83)
	var target_rotation: float = PI / 2.0 if target_pos.x > global_position.x else -PI / 2.0
	
	# Animação de queda em arco até exatamente o local de CaixaPos2
	var tween: Tween = create_tween().set_parallel(true)
	tween.tween_property(self, "global_position:x", target_pos.x, 0.40).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "global_position:y", target_pos.y, 0.40).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	
	var sprite: Sprite2D = get_node_or_null("Sprite2D")
	if sprite:
		tween.tween_property(sprite, "rotation", target_rotation, 0.40).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	
	tween.chain().tween_callback(_on_fall_completed)

func _on_fall_completed() -> void:
	if break_on_land:
		if reveal_item:
			if reveal_item.has_method("reveal"):
				reveal_item.reveal()
			else:
				reveal_item.visible = true
		crate_fallen.emit()
		var sprite: Sprite2D = get_node_or_null("Sprite2D")
		if is_inside_tree() and sprite:
			var break_tween: Tween = create_tween()
			if break_tween:
				break_tween.parallel().tween_property(sprite, "scale", Vector2(1.5, 0.3), 0.08)
				break_tween.parallel().tween_property(sprite, "modulate:a", 0.0, 0.12)
				break_tween.tween_callback(queue_free)
				return
		visible = false
		queue_free()
		return
	
	if target_box:
		target_box.visible = true
		var target_col: CollisionShape2D = target_box.get_node_or_null("CollisionShape2D")
		if target_col:
			target_col.disabled = false
		var target_sprite: Sprite2D = target_box.get_node_or_null("Sprite2D")
		if target_sprite:
			target_sprite.visible = true
	crate_fallen.emit()
	visible = false
	queue_free()
