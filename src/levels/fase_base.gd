extends Node2D

## Legacy / Root game controller.
## Routes input to GameManager and supports fallback switching.

# Usamos get_node_or_null para que não dê erro se o nó não existir na cena
#@onready var caju1: CharacterBody2D = get_node_or_null("Caju")
#@onready var caju2: CharacterBody2D = get_node_or_null("Caju2")
@export var caju1: CharacterBody2D
@export var caju2: CharacterBody2D

var current_player: CharacterBody2D

func _ready() -> void:
	
	# Só configura o caju1 se ele existir na cena
	if caju1:
		current_player = caju1
		if caju1.has_method("make_active"):
			caju1.make_active()
		else:
			print("AVISO: O nó foi encontrado, mas o script 'player.gd' não tem a função 'make_active()' escrita dentro dele.")
	else:
		print("ERRO: O Caju 1 não foi ligado no Inspetor da fase!")
			
	# Só desativa o caju2 se ele também existir na cena
	if caju2:
		if caju2.has_method("make_inactive"):
			caju2.make_inactive()

func _unhandled_input(event: InputEvent) -> void:
	# Only use local fallback when GameManager autoload is not present.
	# GameManager already listens for switch_character globally.
	if not has_node("/root/GameManager"):
		if event.is_action_pressed("switch_character") or event.is_action_pressed("ui_focus_next"):
			switch_character()

func switch_character() -> void:
	# Só permite a troca se AMBOS os personagens existirem na cena
	if caju1 and caju2:
		if current_player == caju1:
			caju1.make_inactive()
			caju2.make_active()
			current_player = caju2
		else:
			caju2.make_inactive()
			caju1.make_active()
			current_player = caju1

func _on_escada_body_entered(body: Node2D) -> void:
	pass # Replace with function body.

func _on_escada_body_exited(body: Node2D) -> void:
	pass # Replace with function body.
