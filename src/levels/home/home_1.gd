class_name LevelHome
extends Node2D

## Main house level controller for Caju Game (Fase 1).
## Manages active character, ladder interaction, tutorial popup,
## and scene transition when both characters reach the top of the ladder.
@onready var som_cair: AudioStreamPlayer = get_node_or_null("SomCair")
var som_tocado: bool = false

const TutorialPopupClass = preload("res://src/ui/tutorial_popup.gd")
const PlayerHUDClass = preload("res://src/ui/player_hud.gd")
const ItemsHUDClass = preload("res://src/ui/items_hud.gd")
const NEXT_LEVEL_PATH = "res://src/levels/home/home_2.tscn"

# Limite superior de Y para considerar que tocou a borda superior da tela
const TOP_SCREEN_Y_THRESHOLD: float = 16.0

var caju: CharacterBody2D
var items_hud: CanvasLayer

var _caju_at_top: bool = false
var _transitioning: bool = false

func _ready() -> void:
	# Localiza o personagem na cena
	if has_node("Caju"):
		caju = get_node("Caju")
	elif has_node("Entities/Players/Caju"):
		caju = get_node("Entities/Players/Caju")

	# Define o Caju como ativo
	if caju and caju.has_method("make_active"):
		caju.make_active()
	
	# Instancia o popup de tutorial com botão '?'
	_setup_tutorial_popup()
	_setup_player_hud()
	_setup_items_hud()
	_setup_crate_link()

func _setup_tutorial_popup() -> void:
	var popup = TutorialPopupClass.new()
	popup.name = "TutorialPopup"
	add_child(popup)

func _setup_player_hud() -> void:
	if not has_node("PlayerHUD"):
		var hud = PlayerHUDClass.new()
		hud.name = "PlayerHUD"
		add_child(hud)

func _setup_items_hud() -> void:
	if has_node("ItemsHUD"):
		items_hud = get_node("ItemsHUD") as CanvasLayer
	else:
		items_hud = ItemsHUDClass.new()
		items_hud.name = "ItemsHUD"
		add_child(items_hud)
	
	# Calcula itens colecionáveis da fase e registra no GameManager
	var total_items: int = 1
	var items_container = get_node_or_null("Items")
	if items_container:
		total_items = max(1, items_container.get_child_count())
	
	if has_node("/root/GameManager"):
		GameManager.set_level_items(total_items)
	if items_hud:
		items_hud.setup(total_items, 0)

func _setup_crate_link() -> void:
	var caixa1 = get_node_or_null("Environment/CaixaPos1")
	var caixa2 = get_node_or_null("Environment/CaixaPos2")
	if caixa1 and caixa2 and "target_box" in caixa1:
		caixa1.target_box = caixa2

func _physics_process(_delta: float) -> void:
	if _transitioning:
		return
	
	# Verifica se o Caju na escada tocou a borda superior da tela
	if caju and "na_escada" in caju:
		if caju.na_escada and caju.position.y <= TOP_SCREEN_Y_THRESHOLD:
			# REGRA: Não pode passar de fase sem coletar todos os itens!
			if has_node("/root/GameManager") and not GameManager.are_all_level_items_collected():
				caju.position.y = TOP_SCREEN_Y_THRESHOLD + 2.0
				_caju_at_top = false
				if items_hud and items_hud.has_method("flash_warning"):
					items_hud.flash_warning()
				return
			
			_caju_at_top = true
		elif not caju.na_escada or caju.position.y > TOP_SCREEN_Y_THRESHOLD + 20.0:
			_caju_at_top = false
	
	# Transita para a nova fase quando Caju terminar de subir tocando o topo
	if _caju_at_top:
		_start_level_transition()

func _on_escada_body_entered(body: Node2D) -> void:
	if "na_escada" in body:
		body.na_escada = true

func _on_escada_body_exited(body: Node2D) -> void:
	if "na_escada" in body:
		body.na_escada = false

func _start_level_transition() -> void:
	if _transitioning:
		return
	_transitioning = true
	print("Ambos os personagens alcançaram o topo da tela! Transitando para Fase 2...")
	
	if has_node("/root/EventBus"):
		get_node("/root/EventBus").level_completed.emit()
	
	# Transição suave para a nova fase
	var timer = get_tree().create_timer(0.4)
	timer.timeout.connect(_load_next_level)

func _load_next_level() -> void:
	get_tree().change_scene_to_file(NEXT_LEVEL_PATH)
