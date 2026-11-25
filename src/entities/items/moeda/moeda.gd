class_name Moeda
extends Area2D

## Moeda especial do jogo.
## Apenas a Kiki consegue enxergar e coletar moedas.

@export var valor: int = 1
@onready var sprite: Sprite2D = $Sprite2D
@onready var collision: CollisionShape2D = $CollisionShape2D

const SOM_ITEM = preload("res://assets/sounds/pickup.mp3")

func _ready() -> void:
	collision_layer = 8 # Layer 4: collectibles
	collision_mask = 2  # Layer 2: player
	
	body_entered.connect(_on_body_entered)
	
	if has_node("/root/EventBus"):
		EventBus.player_swapped.connect(_on_player_swapped)
		
	# Inicia sincronizado com quem for o jogador ativo atual
	call_deferred("_sincronizar_visao_kiki")
	
	# Efeito suave de flutuação
	var tween = create_tween().set_loops()
	tween.tween_property(sprite, "position:y", -3.0, 0.6).set_trans(Tween.TRANS_SINE)
	tween.tween_property(sprite, "position:y", 3.0, 0.6).set_trans(Tween.TRANS_SINE)

func _sincronizar_visao_kiki() -> void:
	if has_node("/root/GameManager"):
		var active = GameManager.active_player
		_atualizar_visibilidade_kiki(active)

func _on_player_swapped(novo_jogador: Node2D) -> void:
	_atualizar_visibilidade_kiki(novo_jogador)

func _atualizar_visibilidade_kiki(jogador: Node2D) -> void:
	var eh_kiki: bool = is_instance_valid(jogador) and ("character_id" in jogador and jogador.character_id == "kiki")
	visible = eh_kiki
	monitoring = eh_kiki
	monitorable = eh_kiki

func _on_body_entered(body: Node2D) -> void:
	# Apenas Kiki pode coletar
	if body and "character_id" in body and body.character_id == "kiki":
		_coletar(body)

func _coletar(collector: CharacterBody2D) -> void:
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)
	
	if has_node("/root/EventBus"):
		EventBus.item_collected.emit("moeda", collector)
		
	if has_node("/root/GameManager"):
		GameManager.score += valor * 5
		
	var audio = AudioStreamPlayer.new()
	audio.stream = SOM_ITEM
	audio.volume_db = -2.0
	audio.bus = &"SFX"
	get_tree().current_scene.add_child(audio)
	audio.play()
	audio.finished.connect(audio.queue_free)
	
	var tween = create_tween()
	tween.parallel().tween_property(sprite, "scale", Vector2(1.5, 1.5), 0.15)
	tween.parallel().tween_property(sprite, "modulate:a", 0.0, 0.15)
	tween.tween_callback(queue_free)
