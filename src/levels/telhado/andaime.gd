class_name Andaime
extends Node2D

## Andaime para escalada no nível do Telhado.
## Ao entrar na área, ativa 'na_escada = true' no jogador para permitir subir/descer.

@onready var area_escada: Area2D = $AreaEscada

func _ready() -> void:
	if area_escada:
		if not area_escada.body_entered.is_connected(_on_body_entered):
			area_escada.body_entered.connect(_on_body_entered)
		if not area_escada.body_exited.is_connected(_on_body_exited):
			area_escada.body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node2D) -> void:
	if body and "na_escada" in body:
		body.na_escada = true

func _on_body_exited(body: Node2D) -> void:
	if body and "na_escada" in body:
		body.na_escada = false
