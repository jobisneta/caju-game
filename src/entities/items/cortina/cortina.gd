extends Node2D
# Supondo que a sua cortina já tem um script de balanço (AnimationPlayer ou código).

@onready var area_agarre: Area2D = $PontoAncora/AreaAgarre
@onready var ponto_ancora = $PontoAncora

func _ready():
	# Conecta o sinal de sobreposição da Area2D
	area_agarre.body_entered.connect(_on_area_agarre_body_entered)

func _on_area_agarre_body_entered(body: Node2D):
	# Vai imprimir no painel "Saída" (Output) o nome de qualquer coisa que encostar
	print("Algo tocou na cortina: ", body.name) 
	
	if body.is_in_group("player") and body.has_method("agarrar_cortina"):
		print("É o Caju! Vai agarrar!")
		body.agarrar_cortina(self, ponto_ancora)
	else:
		print("Bateu, mas falhou no grupo ou não tem a função!")
