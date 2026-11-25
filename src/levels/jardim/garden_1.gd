class_name LevelJardim
extends Node2D

## Garden level controller for Caju Game (garden_1.tscn).
## Environment: Garden / Day (Caju & Tody Co-op).
## Features pushable crate puzzles and character switching.
## Transitions back to Main Menu upon completion.

const TutorialPopupClass = preload("res://src/ui/tutorial_popup.gd")
const PlayerHUDClass = preload("res://src/ui/player_hud.gd")
const CaixaDialogoClass = preload("res://src/ui/caixa_dialogo.tscn")

const EXIT_X_THRESHOLD: float = 1060.0

@export var caju: CharacterBody2D
@export var tody: CharacterBody2D

var current_player: CharacterBody2D
var _completed: bool = false
var tody_preso: bool = true
var _caixa_dialogo: CaixaDialogo = null
var _corrente_sprite: Node2D = null

func _ready() -> void:
	# Localiza o personagem na cena
	if has_node("Caju"):
		caju = get_node("Caju")
		caju.set_camera_limits(0, 1115, 0, 180)
	else:
		push_error("LevelJardim: Caju não foi encontrado!")
	
	if has_node("Tody"):
		tody = get_node("Tody")
		tody.set_camera_limits(0, 1115, 0, 180)
	else:
		push_error("LevelJardim: Tody não foi encontrado!")

	# Define o Caju como ativo inicial
	current_player = caju
	if caju and caju.has_method("make_active"):
		caju.make_active()
	
	if tody and tody.has_method("make_inactive"):
		tody.make_inactive()
		
	# Tody começa preso até o diálogo inicial soltá-lo
	if has_node("/root/GameManager") and tody:
		GameManager.players.erase(tody)
		GameManager.clean_invalid_players()
		
	# Instancia o popup de tutorial e HUD
	_setup_tutorial_popup()
	_setup_player_hud()
	_setup_dialogo()
	_setup_corrente_visual()
	
	# Dispara o diálogo no início da fase do quintal
	call_deferred("iniciar_dialogo_inicial")

func _setup_dialogo() -> void:
	if not has_node("CaixaDialogo"):
		_caixa_dialogo = CaixaDialogoClass.instantiate()
		_caixa_dialogo.name = "CaixaDialogo"
		add_child(_caixa_dialogo)
	else:
		_caixa_dialogo = get_node("CaixaDialogo")

func _setup_corrente_visual() -> void:
	if not is_instance_valid(tody):
		return
		
	# Indicador visual de corrente segurando o Tody
	_corrente_sprite = Line2D.new()
	_corrente_sprite.name = "CorrenteVisual"
	_corrente_sprite.width = 2.0
	_corrente_sprite.default_color = Color(0.65, 0.65, 0.70, 0.95)
	_corrente_sprite.points = PackedVector2Array([
		tody.position + Vector2(6, 12),
		tody.position + Vector2(22, 14)
	])
	add_child(_corrente_sprite)

## Diálogo automático no início do quintal entre Tody e Caju
func iniciar_dialogo_inicial() -> void:
	var falas: Array[Dictionary] = [
		{
			"personagem": "tody",
			"texto": "Au au! Caju! Que bom que você conseguiu sair de casa e vir até o quintal!"
		},
		{
			"personagem": "caju",
			"texto": "Tody! O que aconteceu com você? Por que você está preso nessa corrente?!"
		},
		{
			"personagem": "tody",
			"texto": "O humano me acorrentou aqui fora... Não consigo me mover para alcançar o portão de saída!"
		},
		{
			"personagem": "caju",
			"texto": "Não se preocupe, amigão! Minhas garras conseguem soltar o fecho dessa corrente num instante."
		},
		{
			"personagem": "tody",
			"texto": "Muito obrigado, Caju! Agora que estou solto, podemos empurrar os obstáculos e passar juntos pelo quintal!"
		}
	]
	
	if _caixa_dialogo:
		_caixa_dialogo.iniciar_dialogo(falas)
		_caixa_dialogo.dialogo_finalizado.connect(func():
			tody_preso = false
			if is_instance_valid(_corrente_sprite):
				_corrente_sprite.queue_free()
			if has_node("/root/GameManager") and is_instance_valid(tody):
				GameManager.register_player(tody)
		, CONNECT_ONE_SHOT)

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
	if (caju and caju.position.x >= EXIT_X_THRESHOLD) or (tody and tody.position.x >= EXIT_X_THRESHOLD):
		_on_level_finished()

func _on_level_finished() -> void:
	if _completed:
		return
	_completed = true
	print("Parabéns! Jogo concluído com sucesso! Retornando ao Menu Principal...")
	
	if has_node("/root/EventBus"):
		get_node("/root/EventBus").level_completed.emit()
		
	await get_tree().create_timer(0.4).timeout
	get_tree().change_scene_to_file("res://src/ui/menu_principal.tscn")

func _unhandled_input(event: InputEvent) -> void:
	# Fallback local se GameManager não estiver presente
	if not has_node("/root/GameManager"):
		if not tody_preso and (event.is_action_pressed("switch_character") or event.is_action_pressed("ui_focus_next")):
			switch_character()

func switch_character() -> void:
	if tody_preso:
		return
	if caju and tody:
		if current_player == caju:
			caju.make_inactive()
			tody.make_active()
			current_player = tody
		else:
			tody.make_inactive()
			caju.make_active()
			current_player = caju
