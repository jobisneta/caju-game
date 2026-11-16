extends Control

## Tela de Configurações e Menu de Pause para Caju Game.
## Funciona tanto como tela cheia a partir do menu principal quanto como popup de pause em jogo.

signal continuar_pressionado
signal voltar_pressionado

# Texturas de Música
const TEX_MUSIC_ON = preload("res://assets/art/ui/botao_musicon.png")
const TEX_MUSIC_ON_PRESS = preload("res://assets/art/ui/pressed_musicon.png")
const TEX_MUSIC_OFF = preload("res://assets/art/ui/botao_musicoff.png")
const TEX_MUSIC_OFF_PRESS = preload("res://assets/art/ui/pressed_musicoff.png")

# Texturas de Som
const TEX_SOUND_ON = preload("res://assets/art/ui/botao_soundon.png")
const TEX_SOUND_ON_PRESS = preload("res://assets/art/ui/pressed_soundon.png")
const TEX_SOUND_OFF = preload("res://assets/art/ui/botao_soundoff.png")
const TEX_SOUND_OFF_PRESS = preload("res://assets/art/ui/pressed_soundoff.png")

# Som de feedback para cliques nos botões
const SOM_CLICK = preload("res://assets/sounds/click.wav")

@onready var overlay: ColorRect = $Overlay
@onready var fundo: TextureRect = $Fundo
@onready var botao_continuar: TextureButton = $VBoxContainer/botao_continuar
@onready var botao_musica: TextureButton = $VBoxContainer/botao_musica
@onready var botao_som: TextureButton = $VBoxContainer/botao_som
@onready var botao_voltar: TextureButton = $VBoxContainer/botao_voltar

var is_pause_mode: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_atualizar_botoes()
	
	if has_node("/root/SettingsManager"):
		SettingsManager.music_toggled.connect(func(_enabled): _atualizar_botao_musica())
		SettingsManager.sound_toggled.connect(func(_enabled): _atualizar_botao_som())
	
	# Se aberta diretamente como cena principal (ex: menu principal), desativa modo pause
	if get_tree().current_scene == self:
		configurar_modo_pause(false)

## Configura o visual dependendo se está em modo pause (em jogo) ou menu
func configurar_modo_pause(ativo: bool) -> void:
	is_pause_mode = ativo
	if botao_continuar:
		botao_continuar.visible = ativo
	if overlay:
		overlay.visible = ativo
	if fundo:
		if ativo:
			fundo.self_modulate = Color(1.0, 1.0, 1.0, 0.92)
		else:
			fundo.self_modulate = Color(1.0, 1.0, 1.0, 1.0)
	_atualizar_botoes()

func _unhandled_input(event: InputEvent) -> void:
	# IMPORTANTE: Se o menu estiver oculto, não processa nem consome inputs!
	if not is_visible_in_tree() or not visible:
		return
		
	if event.is_echo():
		return
		
	var is_esc = event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE)
	if not is_esc:
		return
		
	if is_pause_mode:
		_on_botao_continuar_pressed()
		get_viewport().set_input_as_handled()
	elif get_tree().current_scene == self:
		_on_botao_voltar_pressed()
		get_viewport().set_input_as_handled()

func _atualizar_botoes() -> void:
	_atualizar_botao_musica()
	_atualizar_botao_som()

func _atualizar_botao_musica() -> void:
	if not is_instance_valid(botao_musica):
		return
	var is_on: bool = true
	if has_node("/root/SettingsManager"):
		is_on = SettingsManager.music_enabled
		
	if is_on:
		botao_musica.texture_normal = TEX_MUSIC_ON
		botao_musica.texture_pressed = TEX_MUSIC_ON_PRESS
		botao_musica.texture_hover = TEX_MUSIC_ON_PRESS
		botao_musica.modulate = Color(1.0, 1.0, 1.0, 1.0)
	else:
		botao_musica.texture_normal = TEX_MUSIC_OFF
		botao_musica.texture_pressed = TEX_MUSIC_OFF_PRESS
		botao_musica.texture_hover = TEX_MUSIC_OFF_PRESS
		botao_musica.modulate = Color(0.85, 0.85, 0.85, 0.9)

func _atualizar_botao_som() -> void:
	if not is_instance_valid(botao_som):
		return
	var is_on: bool = true
	if has_node("/root/SettingsManager"):
		is_on = SettingsManager.sound_enabled
		
	if is_on:
		botao_som.texture_normal = TEX_SOUND_ON
		botao_som.texture_pressed = TEX_SOUND_ON_PRESS
		botao_som.texture_hover = TEX_SOUND_ON_PRESS
		botao_som.modulate = Color(1.0, 1.0, 1.0, 1.0)
	else:
		botao_som.texture_normal = TEX_SOUND_OFF
		botao_som.texture_pressed = TEX_SOUND_OFF_PRESS
		botao_som.texture_hover = TEX_SOUND_OFF_PRESS
		botao_som.modulate = Color(0.85, 0.85, 0.85, 0.9)

func _tocar_som_click() -> void:
	if has_node("/root/SettingsManager") and not SettingsManager.sound_enabled:
		return
	var player = AudioStreamPlayer.new()
	player.stream = SOM_CLICK
	player.volume_db = -4.0
	player.bus = &"SFX"
	add_child(player)
	player.play()
	player.finished.connect(player.queue_free)

func _on_botao_continuar_pressed() -> void:
	_tocar_som_click()
	continuar_pressionado.emit()
	if is_pause_mode and has_node("/root/SettingsManager"):
		SettingsManager.fechar_pause()

func _on_botao_musica_pressed() -> void:
	_tocar_som_click()
	if has_node("/root/SettingsManager"):
		SettingsManager.toggle_music()
	else:
		_atualizar_botao_musica()

func _on_botao_som_pressed() -> void:
	if has_node("/root/SettingsManager"):
		var novo_estado = SettingsManager.toggle_sound()
		if novo_estado:
			_tocar_som_click()
	else:
		_atualizar_botao_som()

func _on_botao_voltar_pressed() -> void:
	_tocar_som_click()
	voltar_pressionado.emit()
	
	if is_pause_mode:
		if has_node("/root/SettingsManager"):
			SettingsManager.fechar_pause()
		else:
			get_tree().paused = false
			hide()
			
	# Retorna sempre para a tela inicial
	get_tree().change_scene_to_file("res://src/ui/tela_inicial.tscn")
