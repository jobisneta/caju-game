class_name LevelTelhado
extends Node2D

## Rooftop level controller for Caju Game (roof_1.tscn).
## Environment: Rooftop / Night (Caju & Kiki Co-op).
## Routes input to GameManager and supports fallback switching.
## Transitions to Garden (garden_1.tscn) upon reaching the rooftop exit.

const TutorialPopupClass = preload("res://src/ui/tutorial_popup.gd")
const PlayerHUDClass = preload("res://src/ui/player_hud.gd")

@onready var filtro_escuro: CanvasModulate = $FiltroEscuro
@onready var luz_caju: PointLight2D = $Caju/LuzVisao
const VISAO_CAJU := Color(0.08, 0.09, 0.16, 1.0) # Bem escuro (só vê perto da luz)
const VISAO_KIKI := Color(0.65, 0.72, 0.88, 1.0) # Noite leve (enxerga o telhado todo)
const ENERGIA_LUZ_CAJU: float = 0.9

const EXIT_X_THRESHOLD: float = 3100.0

@export var caju: CharacterBody2D
@export var kiki: CharacterBody2D

var current_player: CharacterBody2D
var _completed: bool = false

func _ready() -> void:
	# Localiza o personagem na cena
	if has_node("Caju"):
		caju = get_node("Caju")
		caju.set_camera_limits(0, 3178, 0, 180)
		for filho in $Caju.get_children():
			if filho is PointLight2D:
				luz_caju = filho
				break
	else:
		push_error("LevelTelhado: Caju não foi encontrado!")
	
	if has_node("Kiki"):
		kiki = get_node("Kiki")
		kiki.set_camera_limits(0, 3178, 0, 180)
	else:
		push_error("LevelTelhado: Kiki não foi encontrada!")

	# Define o Caju como ativo inicial
	current_player = caju
	if caju and caju.has_method("make_active"):
		caju.make_active()
	
	if kiki and kiki.has_method("make_inactive"):
		kiki.make_inactive()
		
	# Instancia o popup de tutorial com botão '?'
	_setup_tutorial_popup()
	_setup_player_hud()
	
	if has_node("/root/EventBus"):
		var bus = get_node("/root/EventBus")
		if not bus.player_swapped.is_connected(_on_player_swapped):
			bus.player_swapped.connect(_on_player_swapped)
			
	# Aplica a visão correta assim que a fase começa
	if has_node("/root/GameManager"):
		_atualizar_visao(get_node("/root/GameManager").active_player, true)


func _on_player_swapped(novo_jogador: Node2D) -> void:
	_atualizar_visao(novo_jogador, false)

func _atualizar_visao(jogador: Node2D, instantaneo: bool) -> void:
	if not is_instance_valid(jogador):
		return
		
	var eh_caju: bool = ("character_id" in jogador and jogador.character_id == "caju")
	var cor_alvo: Color = VISAO_CAJU if eh_caju else VISAO_KIKI
	var energia_alvo: float = ENERGIA_LUZ_CAJU if eh_caju else 0.0
	
	if instantaneo:
		if filtro_escuro:
			filtro_escuro.color = cor_alvo
		if luz_caju:
			luz_caju.energy = energia_alvo
			luz_caju.enabled = eh_caju
	else:
		var tween = create_tween().set_parallel(true)
		if filtro_escuro:
			tween.tween_property(filtro_escuro, "color", cor_alvo, 0.3)
		if luz_caju:
			if eh_caju:
				luz_caju.enabled = true
			tween.tween_property(luz_caju, "energy", energia_alvo, 0.3)
			if not eh_caju:
				tween.chain().tween_callback(func(): luz_caju.enabled = false)


func _setup_tutorial_popup() -> void:
	if not has_node("TutorialPopup"):
		var popup = TutorialPopupClass.new()
		popup.name = "TutorialPopup"
		add_child(popup)
		popup.call_deferred("_hide_tutorial")

func _setup_player_hud() -> void:
	if not has_node("PlayerHUD"):
		var hud = PlayerHUDClass.new()
		hud.name = "PlayerHUD"
		add_child(hud)

func _physics_process(_delta: float) -> void:
	if _completed:
		return
	if (caju and caju.position.x >= EXIT_X_THRESHOLD) or (kiki and kiki.position.x >= EXIT_X_THRESHOLD):
		_on_level_finished()

func _on_level_finished() -> void:
	if _completed:
		return
	_completed = true
	print("Parabéns! Fase do Telhado concluída! Transitando para o Jardim (garden_1)...")
	
	if has_node("/root/EventBus"):
		get_node("/root/EventBus").level_completed.emit()
		
	await get_tree().create_timer(0.4).timeout
	get_tree().change_scene_to_file("res://src/levels/jardim/garden_1.tscn")

func _on_queda_area_body_entered(body: Node2D) -> void:
	if body and body.is_in_group("player"):
		print("Queda detectada no abismo do telhado: ", body.name)
		if has_node("/root/GameManager"):
			var gm = get_node("/root/GameManager")
			gm.take_shared_damage(1)
			if gm.shared_health > 0:
				if body.has_method("respawn_at_last_safe_position"):
					body.respawn_at_last_safe_position()
		else:
			if body.has_method("take_damage"):
				body.take_damage(1)
			if body.has_method("respawn_at_last_safe_position"):
				body.respawn_at_last_safe_position()

func _unhandled_input(event: InputEvent) -> void:
	# Only use local fallback when GameManager autoload is not present.
	# GameManager already listens for switch_character globally.
	if not has_node("/root/GameManager"):
		if event.is_action_pressed("switch_character") or event.is_action_pressed("ui_focus_next"):
			switch_character()

func switch_character() -> void:
	# Só permite a troca se AMBOS os personagens existirem na cena
	if caju and kiki:
		if current_player == caju:
			caju.make_inactive()
			kiki.make_active()
			current_player = kiki
		else:
			kiki.make_inactive()
			caju.make_active()
			current_player = caju
