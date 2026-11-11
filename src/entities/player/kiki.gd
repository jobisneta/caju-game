extends Player 

@export_group("Habilidade da Mãe")
@export var cena_mae_coruja: PackedScene
@export var chamadas_maximas: int = 3

var chamadas_restantes: int = 3
var mae_instancia = null
var estado_habilidade = 0 # 0: Livre, 1: Mãe voando, 2: Galho solto (mãe indo embora)

func _ready() -> void:
	super._ready() 
	chamadas_restantes = chamadas_maximas

func _process_active_input(delta: float) -> void:
	super._process_active_input(delta)
	
	# Caso click_p seja acionado isoladamente
	if Input.is_action_just_pressed("click_p") and not Input.is_action_just_pressed("interact"):
		interact_with_nearby()

func interact_with_nearby() -> bool:
	var did_interact: bool = super.interact_with_nearby()
	if not did_interact:
		usar_habilidade_galho()
	return did_interact

func usar_habilidade_galho() -> void:
	# Se o galho já caiu e a mãe saiu da cena (queue_free), libera para a próxima chamada
	if estado_habilidade == 2 and not is_instance_valid(mae_instancia):
		estado_habilidade = 0
		
	if estado_habilidade == 0:
		if chamadas_restantes > 0:
			print("Kiki: Fiu fiu! (Assobio)") 
			
			if cena_mae_coruja:
				mae_instancia = cena_mae_coruja.instantiate()
				get_tree().current_scene.add_child(mae_instancia)
				
				# Mantém a sua rota original ajustada
				var pos_inicio = global_position + Vector2(-300, -105)
				var pos_fim = global_position + Vector2(300, -40)
				
				mae_instancia.iniciar_voo(pos_inicio, pos_fim)
				estado_habilidade = 1
		else:
			print("Kiki: A mãe tá cansada! (Sem chamadas restantes)")
			
	elif estado_habilidade == 1:
		if is_instance_valid(mae_instancia) and mae_instancia.has_method("soltar_galho"):
			mae_instancia.soltar_galho()
			chamadas_restantes -= 1
			print("Galho solto! Usos restantes: ", chamadas_restantes)
			estado_habilidade = 2 # Aguarda a mãe sair da tela para reativar
