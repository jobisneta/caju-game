class_name Tirolesa
extends Node2D

## Mecânica de tirolesa / cabo de descida para o nível do Telhado.
## Ao alcançar o início do cabo, o personagem desliza automaticamente até o destino.

@export var ponto_inicio: Vector2 = Vector2.ZERO
@export var ponto_fim: Vector2 = Vector2(270, 90)
@export var duracao_slide: float = 1.3

@onready var linha_cabo: Line2D = $LinhaCabo
@onready var area_gatilho: Area2D = $AreaGatilho

var _deslizando: bool = false

func _ready() -> void:
	if linha_cabo:
		linha_cabo.clear_points()
		linha_cabo.add_point(ponto_inicio)
		# Suave curvatura do cabo
		var meio = (ponto_inicio + ponto_fim) * 0.5 + Vector2(0, 15)
		linha_cabo.add_point(meio)
		linha_cabo.add_point(ponto_fim)
		
	if area_gatilho:
		area_gatilho.position = ponto_inicio
		if not area_gatilho.body_entered.is_connected(_on_body_entered):
			area_gatilho.body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if _deslizando or not (body is CharacterBody2D):
		return
		
	# Apenas personagem na camada de player
	if not body.is_in_group("player"):
		return
		
	_deslizar_personagem(body)

func _deslizar_personagem(personagem: CharacterBody2D) -> void:
	_deslizando = true
	var pos_global_inicio = to_global(ponto_inicio)
	var pos_global_meio = to_global((ponto_inicio + ponto_fim) * 0.5 + Vector2(0, 15))
	var pos_global_fim = to_global(ponto_fim)
	
	personagem.global_position = pos_global_inicio
	personagem.velocity = Vector2.ZERO
	
	# Desativa controle durante o deslizamento
	var era_ativo = ("is_active" in personagem and personagem.is_active)
	if era_ativo and personagem.has_method("make_inactive"):
		personagem.make_inactive()
		
	var tween = create_tween()
	# Primeiro trecho até o meio
	tween.tween_property(personagem, "global_position", pos_global_meio, duracao_slide * 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	# Segundo trecho até o fim
	tween.tween_property(personagem, "global_position", pos_global_fim, duracao_slide * 0.55).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	
	tween.finished.connect(func():
		_deslizando = false
		if era_ativo and is_instance_valid(personagem) and personagem.has_method("make_active"):
			personagem.make_active()
			personagem.velocity = Vector2(80.0, 0.0) # Leve impulso ao aterrissar
	)
