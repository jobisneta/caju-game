class_name LevelHome3
extends Node2D

## Third house level controller for Caju Game (Fase 3 - Salão das Cortinas).
## Environment: House (hallway with swing curtains).
## Mode: Solo Caju. Manages camera limits, curtain swing, and transition to Rooftop (roof_1).

const TutorialPopupClass = preload("res://src/ui/tutorial_popup.gd")
const PlayerHUDClass = preload("res://src/ui/player_hud.gd")

const EXIT_X_THRESHOLD: float = 1220.0

@export var caju: CharacterBody2D

var _completed: bool = false

func _ready() -> void:
	if has_node("Caju"):
		caju = get_node("Caju")
		caju.set_camera_limits(0, 1280, 0, 180)
		if caju.has_method("make_active"):
			caju.make_active()
	else:
		push_error("LevelHome3: Caju não foi encontrado!")
		
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
	if caju and caju.position.x >= EXIT_X_THRESHOLD:
		_on_level_finished()

func _on_level_finished() -> void:
	if _completed:
		return
	_completed = true
	print("Parabéns! Fase 3 concluída! Transitando para o Telhado (roof_1)...")
	
	if has_node("/root/EventBus"):
		get_node("/root/EventBus").level_completed.emit()
		
	await get_tree().create_timer(0.4).timeout
	get_tree().change_scene_to_file("res://src/levels/telhado/roof_1.tscn")
