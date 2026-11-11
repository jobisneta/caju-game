class_name LevelJardim
extends Node2D

## Garden level controller for Caju Game (garden_1.tscn).
## Environment: Garden / Day (Caju & Tody Co-op).
## Features pushable crate puzzles and character switching.
## Transitions back to Main Menu upon completion.

const TutorialPopupClass = preload("res://src/ui/tutorial_popup.gd")
const PlayerHUDClass = preload("res://src/ui/player_hud.gd")

const EXIT_X_THRESHOLD: float = 1060.0

@export var caju: CharacterBody2D
@export var tody: CharacterBody2D

var current_player: CharacterBody2D
var _completed: bool = false

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
		
	# Instancia o popup de tutorial com botão '?'
	_setup_tutorial_popup()
	_setup_player_hud()

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
	# Only use local fallback when GameManager autoload is not present.
	# GameManager already listens for switch_character globally.
	if not has_node("/root/GameManager"):
		if event.is_action_pressed("switch_character") or event.is_action_pressed("ui_focus_next"):
			switch_character()

func switch_character() -> void:
	# Só permite a troca se AMBOS os personagens existirem na cena
	if caju and tody:
		if current_player == caju:
			caju.make_inactive()
			tody.make_active()
			current_player = tody
		else:
			tody.make_inactive()
			caju.make_active()
			current_player = caju
