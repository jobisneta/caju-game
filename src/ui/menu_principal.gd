extends Control

## Main Menu Controller for Caju Game.

func _ready() -> void:
	pass

func _on_botao_novo_pressed() -> void:
	get_tree().change_scene_to_file("res://src/levels/home/home_1.tscn")

func _on_botao_continuar_pressed() -> void:
	# Inicia o jogo a partir do início ou ponto salvo
	get_tree().change_scene_to_file("res://src/levels/home/home_1.tscn")

func _on_botao_opcoes_pressed() -> void:
	print("Opções: Configurações de som e controles (em breve)")
