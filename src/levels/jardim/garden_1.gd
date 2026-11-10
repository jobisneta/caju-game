extends Node2D

## Legacy / Root game controller.
## Routes input to GameManager and supports fallback switching.

const TutorialPopupClass = preload("res://src/ui/tutorial_popup.gd")
const PlayerHUDClass = preload("res://src/ui/player_hud.gd")

@export var caju: CharacterBody2D
@export var tody: CharacterBody2D

var current_player: CharacterBody2D

func _ready() -> void:
	# Localiza o personagem na cena
	if has_node("Caju"):
		caju = get_node("Caju")
		caju.set_camera_limits(0, 1115, 0, 180)
	else:
		print("ERRO: Caju não foi encontrado!")
	
	if has_node("Tody"):
		tody = get_node("Tody")
		tody.set_camera_limits(0, 1115, 0, 180)
	else:
		print("ERRO: Tody não foi encontrada!")

	# Define o Caju como ativo inicial
	current_player = caju
	if caju and caju.has_method("make_active"):
		caju.make_active()
	else:
		print("ERRO: Caju sem make_active!")
	
	if tody and tody.has_method("make_inactive"):
		tody.make_inactive()
	else:
		print("ERRO: Tody sem make_active!")
		
	# Instancia o popup de tutorial com botão '?'
	_setup_tutorial_popup()
	_setup_player_hud()

func _setup_tutorial_popup() -> void:
	if not has_node("TutorialPopup"):
		var popup = TutorialPopupClass.new()
		popup.name = "TutorialPopup"
		add_child(popup)

func _setup_player_hud() -> void:
	if not has_node("PlayerHUD"):
		var hud = PlayerHUDClass.new()
		hud.name = "PlayerHUD"
		add_child(hud)

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
