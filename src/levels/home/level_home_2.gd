class_name LevelHome2
extends Node2D

## Second house level controller for Caju Game (Fase 2).
## Environment: House (upper floor / continuation).
## Manages character switching, ladder mechanics, and completion.

const TutorialPopupClass = preload("res://src/ui/tutorial_popup.gd")
const TOP_SCREEN_Y_THRESHOLD: float = 16.0

var caju1: CharacterBody2D
var caju2: CharacterBody2D

var _caju1_at_top: bool = false
var _caju2_at_top: bool = false
var _completed: bool = false

func _ready() -> void:
	if has_node("Caju"):
		caju1 = get_node("Caju")
	elif has_node("Entities/Players/Caju"):
		caju1 = get_node("Entities/Players/Caju")
		
	if has_node("Caju2"):
		caju2 = get_node("Caju2")
	elif has_node("Entities/Players/Caju2"):
		caju2 = get_node("Entities/Players/Caju2")

	if caju1 and caju1.has_method("make_active"):
		caju1.make_active()
	if caju2 and caju2.has_method("make_inactive"):
		caju2.make_inactive()

	# Instancia o tutorial popup (com botão '?' no canto)
	_setup_tutorial_popup()

func _setup_tutorial_popup() -> void:
	var popup = TutorialPopupClass.new()
	popup.name = "TutorialPopup"
	add_child(popup)
	# Na fase 2, podemos deixar já fechado com o '?' visível
	# Mas como o TutorialPopup abre e fecha com 'Entendido', o jogador pode fechar ou consultar
	# Vamos fechar direto se preferir, ou deixar padrão
	popup.call_deferred("_hide_tutorial")

func _physics_process(_delta: float) -> void:
	if _completed:
		return
	
	if caju1 and "na_escada" in caju1:
		if caju1.na_escada and caju1.position.y <= TOP_SCREEN_Y_THRESHOLD:
			_caju1_at_top = true
		elif not caju1.na_escada or caju1.position.y > TOP_SCREEN_Y_THRESHOLD + 20.0:
			_caju1_at_top = false
			
	if caju2 and "na_escada" in caju2:
		if caju2.na_escada and caju2.position.y <= TOP_SCREEN_Y_THRESHOLD:
			_caju2_at_top = true
		elif not caju2.na_escada or caju2.position.y > TOP_SCREEN_Y_THRESHOLD + 20.0:
			_caju2_at_top = false
	
	if _caju1_at_top and _caju2_at_top:
		_on_level_finished()

func _on_escada_body_entered(body: Node2D) -> void:
	if "na_escada" in body:
		body.na_escada = true

func _on_escada_body_exited(body: Node2D) -> void:
	if "na_escada" in body:
		body.na_escada = false

func _on_level_finished() -> void:
	if _completed:
		return
	_completed = true
	print("Parabéns! Fase 2 concluída com ambos os personagens!")
	
	if has_node("/root/EventBus"):
		get_node("/root/EventBus").level_completed.emit()
