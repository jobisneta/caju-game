extends Control

## Main Menu Controller for Caju Game.

@onready var botao_continuar: TextureButton = $VBoxContainer/botao_continuar

func _ready() -> void:
	# O botão de continuar só aparece se houver um save válido
	if has_node("/root/GameManager"):
		botao_continuar.visible = GameManager.has_save()
	else:
		botao_continuar.visible = false

func _tocar_click() -> void:
	if has_node("/root/SettingsManager"):
		SettingsManager.play_click_sound()

func _on_botao_novo_pressed() -> void:
	_tocar_click()
	if has_node("/root/GameManager"):
		GameManager.start_new_game()
	else:
		get_tree().change_scene_to_file("res://src/levels/home/home_1.tscn")

func _on_botao_continuar_pressed() -> void:
	_tocar_click()
	if has_node("/root/GameManager") and GameManager.has_save():
		GameManager.load_and_continue_game()
	else:
		get_tree().change_scene_to_file("res://src/levels/home/home_1.tscn")

func _on_botao_opcoes_pressed() -> void:
	_tocar_click()
	get_tree().change_scene_to_file("res://src/ui/tela_configuracoes.tscn")
