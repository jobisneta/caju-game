class_name PushableCrate
extends StaticBody2D

## Interactive Pushable Crate for Caju Game.
## Falls from CaixaPos1 to CaixaPos2 when Caju interacts from the right side.

signal crate_fallen

@export var target_box: StaticBody2D
@export var requires_right_side: bool = true

var _is_fallen: bool = false
var som_tocado: bool = false

func _ready() -> void:
	add_to_group("interactable")
	# Ativa camada 1 (world) e camada 10 (interactables: bit 10 = 512)
	collision_layer = 1 | 512

func interact(player: CharacterBody2D) -> void:
	if _is_fallen:
		return
	
	if requires_right_side and player:
		# Verifica se o jogador está posicionado à direita da caixa
		if player.global_position.x <= global_position.x + 4.0:
			print("[PushableCrate] O Caju precisa estar à direita da caixa para derrubá-la para a esquerda.")
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
	
	# Animação de queda para a esquerda até exatamente o local de CaixaPos2
	var tween = create_tween().set_parallel(true)
	tween.tween_property(self, "global_position:x", target_pos.x, 0.40).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "global_position:y", target_pos.y, 0.40).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	
	var sprite: Sprite2D = get_node_or_null("Sprite2D")
	if sprite:
		tween.tween_property(sprite, "rotation", -PI / 2.0, 0.40).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	
	tween.chain().tween_callback(_on_fall_completed)

func _on_fall_completed() -> void:
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
