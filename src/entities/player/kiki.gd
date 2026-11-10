extends Player # Herda automaticamente tudo do seu player.gd!

@export_group("Habilidade da Mãe")
@export var cena_mae_coruja: PackedScene
var mae_instancia = null
var estado_habilidade = 0 # 0: Mãe disponível, 1: Mãe voando, 2: Galho já caiu

# Sobrescrevemos a função de input ativo do player.gd
func _process_active_input(delta: float) -> void:
	# 1. Roda todo o código original (andar, pular, planar, interagir)
	super._process_active_input(delta)
	
	# 2. Adiciona a lógica exclusiva da Kiki
	# DICA: Criei uma ação "chamar_mae" para não conflitar com o seu "interact" 
	# (senão ela chamaria a mãe toda vez que fosse ler uma placa com 'E')
	if Input.is_action_just_pressed("click_p"):
		usar_habilidade_galho()

func usar_habilidade_galho() -> void:
	if estado_habilidade == 0:
		print("Kiki: Fiu fiu! (Assobio)") 
		
		if cena_mae_coruja:
			mae_instancia = cena_mae_coruja.instantiate()
			# Adiciona a mãe na cena principal (fase) para ela não seguir a câmera da Kiki
			get_tree().current_scene.add_child(mae_instancia)
			
			# Define a rota de voo (da esquerda para a direita, acima da Kiki)
			var pos_inicio = global_position + Vector2(-300, -105)
			var pos_fim = global_position + Vector2(300, -40)
			
			mae_instancia.iniciar_voo(pos_inicio, pos_fim)
			estado_habilidade = 1
			
	elif estado_habilidade == 1:
		if mae_instancia != null and mae_instancia.has_method("soltar_galho"):
			mae_instancia.soltar_galho()
			estado_habilidade = 2 # Evita spam de galhos
