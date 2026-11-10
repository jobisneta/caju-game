extends CharacterBody2D

@onready var ray_esq = $RayEsq
@onready var ray_dir = $RayDir

var caindo: bool = true
var gravidade: float = 800.0

func _ready():
	# Garante que os sensores estão a procurar pelo cenário (Layer 1)
	ray_esq.collision_mask = 1
	ray_dir.collision_mask = 1
	
	# Desliga a máscara física para o galho virar um "fantasma" enquanto cai.
	# Isso impede que o meio dele fique enroscado nas quinas do telhado!
	set_collision_mask_value(1, false)
	set_collision_layer_value(1, false)

func _physics_process(delta: float) -> void:
	if caindo:
		velocity.y += gravidade * delta
		
		# Move o galho ignorando a física tradicional
		global_position += velocity * delta
		
		# Atualiza os sensores a cada frame
		ray_esq.force_raycast_update()
		ray_dir.force_raycast_update()
		
		var bateu_esq = ray_esq.is_colliding()
		var bateu_dir = ray_dir.is_colliding()
		
		# CONDIÇÃO DE SUCESSO: As duas pontas acharam um telhado!
		if bateu_esq and bateu_dir:
			caindo = false
			velocity = Vector2.ZERO
			rotation_degrees = 0.0
			
			# Opcional: Ajuste fino para a ponte não afundar no telhado.
			# Puxa o galho para a exata altura do telhado mais alto que ele tocou.
			var altura_esq = ray_esq.get_collision_point().y
			var altura_dir = ray_dir.get_collision_point().y
			global_position.y = min(altura_esq, altura_dir)
			
			# Transforma o fantasma em chão sólido para a Kiki pisar (Layer 1 = Ativa)
			set_collision_layer_value(1, true)
			
		else:
			# FEEDBACK DE ERRO: Bateu só de um lado ou errou o buraco
			if bateu_esq:
				rotation_degrees = move_toward(rotation_degrees, 60.0, 350.0 * delta)
			elif bateu_dir:
				rotation_degrees = move_toward(rotation_degrees, -60.0, 350.0 * delta)

		# Limpeza: Se o galho cair no abismo infinito, destrói-o para não pesar o jogo
		if global_position.y > 2000:
			queue_free()
