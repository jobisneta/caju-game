extends Node

## Gerenciador global de configurações e pause para Caju Game.
## Salva e carrega preferências de áudio, gerencia barramentos e controla o popup de pause.

signal music_toggled(is_enabled: bool)
signal sound_toggled(is_enabled: bool)
signal settings_changed
signal pause_opened
signal pause_closed

const SAVE_PATH: String = "user://settings.cfg"
const SOM_CLICK = preload("res://assets/sounds/click.wav")

var music_enabled: bool = true
var sound_enabled: bool = true

var config: ConfigFile = ConfigFile.new()

# Popup de pause global
var pause_canvas: CanvasLayer = null
var pause_menu_instance: Control = null

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	ensure_buses()
	load_settings()
	apply_settings()
	
	# Monitora novos nós de áudio adicionados na árvore de nós
	get_tree().node_added.connect(_on_node_added)
	
	# Instancia o CanvasLayer de pause
	call_deferred("_setup_pause_menu")

func _setup_pause_menu() -> void:
	if pause_canvas != null:
		return
		
	pause_canvas = CanvasLayer.new()
	pause_canvas.name = "PauseCanvasLayer"
	pause_canvas.layer = 100
	pause_canvas.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(pause_canvas)
	
	var scene = preload("res://src/ui/tela_configuracoes.tscn")
	pause_menu_instance = scene.instantiate()
	pause_menu_instance.process_mode = Node.PROCESS_MODE_ALWAYS
	pause_canvas.add_child(pause_menu_instance)
	
	pause_canvas.hide()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_echo():
		return
		
	var is_esc = event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE)
	if not is_esc:
		return
		
	if is_pause_aberto():
		fechar_pause()
		get_viewport().set_input_as_handled()
	else:
		var current_scene = get_tree().current_scene
		# O pause com ESC só ativa durante as fases do jogo (res://src/levels/...)
		if current_scene and current_scene.scene_file_path.begins_with("res://src/levels/"):
			# Não abre se outro popup (como tutorial) já pausou a árvore
			if not get_tree().paused:
				abrir_pause()
				get_viewport().set_input_as_handled()

## Verifica se o popup de pause está atualmente visível na tela
func is_pause_aberto() -> bool:
	return pause_canvas != null and pause_canvas.visible

## Abre o popup de configurações em modo pause e pausa a árvore do jogo
func abrir_pause() -> void:
	if pause_canvas == null or pause_menu_instance == null:
		_setup_pause_menu()
		
	pause_menu_instance.configurar_modo_pause(true)
	pause_canvas.show()
	get_tree().paused = true
	pause_opened.emit()

## Fecha o popup de pause e retoma o jogo
func fechar_pause() -> void:
	if pause_canvas != null:
		pause_canvas.hide()
	if pause_menu_instance != null:
		pause_menu_instance.configurar_modo_pause(false)
		
	# Limpa qualquer foco de UI para evitar que botões continuem capturando teclas
	var focus_owner = get_viewport().gui_get_focus_owner()
	if focus_owner:
		focus_owner.release_focus()
		
	get_tree().paused = false
	pause_closed.emit()

## Toca o som de clique padrão nos botões da interface
func play_click_sound() -> void:
	if not sound_enabled:
		return
	var player = AudioStreamPlayer.new()
	player.stream = SOM_CLICK
	player.volume_db = -4.0
	player.bus = &"SFX"
	add_child(player)
	player.play()
	player.finished.connect(player.queue_free)

## Garante que os barramentos 'Music' e 'SFX' existam na AudioServer
func ensure_buses() -> void:
	if AudioServer.get_bus_index("Music") == -1:
		AudioServer.add_bus()
		var idx = AudioServer.bus_count - 1
		AudioServer.set_bus_name(idx, "Music")
		AudioServer.set_bus_send(idx, "Master")
		
	if AudioServer.get_bus_index("SFX") == -1:
		AudioServer.add_bus()
		var idx = AudioServer.bus_count - 1
		AudioServer.set_bus_name(idx, "SFX")
		AudioServer.set_bus_send(idx, "Master")

## Direciona automaticamente players de áudio para o barramento correto
func _on_node_added(node: Node) -> void:
	if node is AudioStreamPlayer or node is AudioStreamPlayer2D:
		var node_name = node.name.to_lower()
		if node.bus == &"Master" or node.bus == &"":
			if "music" in node_name or "musica" in node_name:
				node.bus = &"Music"
			else:
				node.bus = &"SFX"

## Alterna estado da música
func toggle_music() -> bool:
	set_music_enabled(not music_enabled)
	return music_enabled

## Alterna estado dos efeitos sonoros
func toggle_sound() -> bool:
	set_sound_enabled(not sound_enabled)
	return sound_enabled

## Define estado da música
func set_music_enabled(val: bool) -> void:
	music_enabled = val
	var bus_idx = AudioServer.get_bus_index("Music")
	if bus_idx != -1:
		AudioServer.set_bus_mute(bus_idx, not music_enabled)
	save_settings()
	music_toggled.emit(music_enabled)
	settings_changed.emit()

## Define estado dos sons
func set_sound_enabled(val: bool) -> void:
	sound_enabled = val
	var bus_idx = AudioServer.get_bus_index("SFX")
	if bus_idx != -1:
		AudioServer.set_bus_mute(bus_idx, not sound_enabled)
	save_settings()
	sound_toggled.emit(sound_enabled)
	settings_changed.emit()

## Aplica as configurações atuais nos barramentos
func apply_settings() -> void:
	ensure_buses()
	var music_idx = AudioServer.get_bus_index("Music")
	if music_idx != -1:
		AudioServer.set_bus_mute(music_idx, not music_enabled)
		
	var sfx_idx = AudioServer.get_bus_index("SFX")
	if sfx_idx != -1:
		AudioServer.set_bus_mute(sfx_idx, not sound_enabled)

## Salva preferências em user://settings.cfg
func save_settings() -> void:
	config.set_value("audio", "music_enabled", music_enabled)
	config.set_value("audio", "sound_enabled", sound_enabled)
	var err = config.save(SAVE_PATH)
	if err != OK:
		push_warning("SettingsManager: Não foi possível salvar em %s" % SAVE_PATH)

## Carrega preferências salvas
func load_settings() -> void:
	var err = config.load(SAVE_PATH)
	if err == OK:
		music_enabled = config.get_value("audio", "music_enabled", true)
		sound_enabled = config.get_value("audio", "sound_enabled", true)
	else:
		music_enabled = true
		sound_enabled = true
