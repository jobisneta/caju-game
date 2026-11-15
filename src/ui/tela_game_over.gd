extends Control

var pode_continuar: bool = false

func _ready() -> void:
	# Garante que esta tela receba comandos mesmo se algum script pausou o jogo
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().paused = false
	
	await get_tree().create_timer(0.5).timeout
	pode_continuar = true
	print("Game Over pronto para receber tecla.")

func _input(event: InputEvent) -> void:
	if not pode_continuar:
		return
		
	var apertou_tecla = event is InputEventKey and event.pressed and not event.echo
	var clicou_mouse = event is InputEventMouseButton and event.pressed
	var apertou_controle = event is InputEventJoypadButton and event.pressed
	
	if apertou_tecla or clicou_mouse or apertou_controle:
		pode_continuar = false
		if has_node("/root/GameManager"):
			get_node("/root/GameManager").reiniciar_apos_gameover()
