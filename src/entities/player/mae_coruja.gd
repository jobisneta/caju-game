extends Node2D

@export var cena_galho: PackedScene
var carregando_galho = true

# Função chamada pela Kiki para fazer a mãe atravessar a tela
func iniciar_voo(pos_inicial: Vector2, pos_final: Vector2):
	global_position = pos_inicial
	$animacoes.play("voando_galho")
	
	# Cria a animação de movimento usando Tween (Godot 4)
	var tween = get_tree().create_tween()
	# Ajuste o tempo (ex: 4.0 segundos) dependendo do tamanho da sua fase
	tween.tween_property(self, "global_position", pos_final, 4.0) 
	# Quando o voo terminar, a mãe some da cena
	tween.finished.connect(queue_free)

func soltar_galho():
	if carregando_galho:
		carregando_galho = false
		$animacoes.play("voando")
		
		# Instancia o galho no mundo
		var galho = cena_galho.instantiate()
		galho.global_position = global_position
		# Adiciona o galho na cena principal (fase) para ele não sumir quando a mãe sumir
		get_tree().current_scene.add_child(galho)
