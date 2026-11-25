class_name CaixaDialogo
extends CanvasLayer

## Componente global de caixa de diálogo para Caju Game.
## Exibe retrato do personagem ao lado da caixa de diálogo com texto animado.

signal dialogo_iniciado
signal dialogo_finalizado
signal linha_avancada(indice: int)

const FONT_PIXEL = preload("res://assets/art/ui/PixelifySans-VariableFont_wght.ttf")
const TEX_CAIXA = preload("res://assets/art/ui/caixa_dialogo.png")
const SOM_CLICK = preload("res://assets/sounds/click.wav")

const RETRATOS = {
	"caju": preload("res://assets/art/ui/dialogo_caju.png"),
	"kiki": preload("res://assets/art/ui/dialogo_kiki.png"),
	"tody": preload("res://assets/art/ui/dialogo_tody.png"),
}

const NOMES = {
	"caju": "Caju",
	"kiki": "Kiki",
	"tody": "Tody",
}

# Cores temáticas do texto
const COR_NOME = Color(0.24, 0.16, 0.10) # Marrom escuro temático
const COR_TEXTO = Color(0.20, 0.18, 0.16) # Quase preto legível

var falas: Array[Dictionary] = []
var indice_atual: int = 0
var animando_texto: bool = false
var texto_completo_atual: String = ""

@onready var root_control: Control = $Control
@onready var container_dialogo: Control = $Control/ContainerDialogo
@onready var retrato_rect: TextureRect = $Control/ContainerDialogo/Retrato
@onready var caixa_painel: NinePatchRect = $Control/ContainerDialogo/CaixaFundo
@onready var nome_label: Label = $Control/ContainerDialogo/CaixaFundo/Margin/VBox/NomeLabel
@onready var texto_label: Label = $Control/ContainerDialogo/CaixaFundo/Margin/VBox/TextoLabel
@onready var indicador_proximo: Label = $Control/ContainerDialogo/CaixaFundo/Indicador

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 95
		
	hide_dialogo()

## Inicia uma sequência de diálogos.
## Cada item de 'lista_falas' deve ser um Dictionary: {"personagem": "caju"|"kiki"|"tody", "texto": "..."}
func iniciar_dialogo(lista_falas: Array[Dictionary]) -> void:
	if lista_falas.is_empty():
		return
	falas = lista_falas
	indice_atual = 0
	root_control.show()
	show()
	dialogo_iniciado.emit()
	
	# Desativa controles dos jogadores durante o diálogo
	if has_node("/root/GameManager"):
		var gm = get_node("/root/GameManager")
		if gm.active_player and gm.active_player.has_method("make_inactive"):
			gm.active_player.make_inactive()
			
	_exibir_fala_atual()

func _exibir_fala_atual() -> void:
	if indice_atual >= falas.size():
		finalizar_dialogo()
		return
		
	var fala = falas[indice_atual]
	var char_id = fala.get("personagem", "caju").to_lower()
	var texto = fala.get("texto", "")
	
	# Atualiza retrato ao lado da caixa
	if RETRATOS.has(char_id):
		retrato_rect.texture = RETRATOS[char_id]
		retrato_rect.show()
	else:
		retrato_rect.hide()
		
	# Atualiza nome
	nome_label.text = NOMES.get(char_id, char_id.capitalize())
	
	# Efeito máquina de escrever
	texto_completo_atual = texto
	texto_label.text = texto
	texto_label.visible_characters = 0
	animando_texto = true
	indicador_proximo.hide()
	
	var tween = create_tween()
	var duracao: float = max(0.35, float(texto.length()) * 0.022)
	tween.tween_property(texto_label, "visible_characters", texto.length(), duracao)
	tween.finished.connect(func():
		animando_texto = false
		indicador_proximo.show()
	)

func avancar() -> void:
	_tocar_click()
	if animando_texto:
		# Pula a animação e mostra tudo imediatamente
		animando_texto = false
		texto_label.visible_characters = -1
		indicador_proximo.show()
	else:
		indice_atual += 1
		linha_avancada.emit(indice_atual)
		_exibir_fala_atual()

func finalizar_dialogo() -> void:
	hide_dialogo()
	if has_node("/root/GameManager"):
		var gm = get_node("/root/GameManager")
		if gm.active_player and gm.active_player.has_method("make_active"):
			gm.active_player.make_active()
	dialogo_finalizado.emit()

func hide_dialogo() -> void:
	if is_instance_valid(root_control):
		root_control.hide()
	hide()

func _unhandled_input(event: InputEvent) -> void:
	if not visible or not root_control.visible:
		return
		
	var acionado: bool = (
		event.is_action_pressed("interact") or
		event.is_action_pressed("jump") or
		event.is_action_pressed("ui_accept") or
		(event is InputEventKey and event.pressed and not event.echo and event.keycode in [KEY_SPACE, KEY_ENTER, KEY_E, KEY_P]) or
		(event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT)
	)
	
	if acionado:
		avancar()
		get_viewport().set_input_as_handled()

func _tocar_click() -> void:
	if has_node("/root/SettingsManager"):
		SettingsManager.play_click_sound()
