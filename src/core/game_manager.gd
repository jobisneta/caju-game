extends Node

## Global Game Manager for Caju Game.
## Coordinates player registry, character switching, score, shared health and global gameplay state.

const SOM_DERROTA = preload("res://assets/sounds/game_over_sound.wav")
const SOM_ITEM = preload ("res://assets/sounds/pickup.mp3")

var cena_para_reiniciar: String = ""
var active_player: CharacterBody2D = null
var players: Array[CharacterBody2D] = []
var collected_bottles: int = 0
var score: int = 0
var level_total_items: int = 0
var level_collected_items: int = 0


@export var shared_max_health: int = 3
var shared_health: int = 3

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	shared_health = shared_max_health
	if has_node("/root/EventBus"):
		var bus = get_node("/root/EventBus")
		if not bus.level_completed.is_connected(_on_level_completed):
			bus.level_completed.connect(_on_level_completed)
		if not bus.item_collected.is_connected(_on_item_collected):
			bus.item_collected.connect(_on_item_collected)

func _unhandled_input(event: InputEvent) -> void:
	var tree: SceneTree = get_tree()
	if tree and tree.paused:
		return
	if event.is_action_pressed("switch_character") or event.is_action_pressed("ui_focus_next"):
		switch_player()

func clean_invalid_players() -> void:
	players = players.filter(func(p: CharacterBody2D) -> bool: return is_instance_valid(p))
	if active_player != null and not is_instance_valid(active_player):
		active_player = players[0] if players.size() > 0 else null

func clear_players() -> void:
	players.clear()
	active_player = null

func register_player(player: CharacterBody2D) -> void:
	clean_invalid_players()
	if not is_instance_valid(player):
		return
	if not players.has(player):
		players.append(player)
		if active_player == null:
			if ("is_active" in player and player.is_active) or players.size() == 1:
				active_player = player

func unregister_player(player: CharacterBody2D) -> void:
	players.erase(player)
	clean_invalid_players()
	if active_player == player:
		active_player = players[0] if players.size() > 0 else null

func switch_player() -> void:
	clean_invalid_players()
	if players.size() < 2:
		return
	
	var current_index: int = players.find(active_player)
	if current_index == -1:
		current_index = 0
	var next_index: int = (current_index + 1) % players.size()
	
	if is_instance_valid(active_player) and active_player.has_method("make_inactive"):
		active_player.make_inactive()
		
	active_player = players[next_index]
	if is_instance_valid(active_player) and active_player.has_method("make_active"):
		active_player.make_active()
		
	if has_node("/root/EventBus"):
		EventBus.player_swapped.emit(active_player)

func set_level_items(total: int) -> void:
	level_total_items = total
	level_collected_items = 0
	if has_node("/root/EventBus"):
		EventBus.level_items_updated.emit(level_collected_items, level_total_items)

func are_all_level_items_collected() -> bool:
	return level_collected_items >= level_total_items

func collect_bottle(collector: CharacterBody2D) -> void:
	collected_bottles += 1
	level_collected_items += 1
	score += 10
	if has_node("/root/EventBus"):
		EventBus.item_collected.emit("bottle", collector)
		EventBus.level_items_updated.emit(level_collected_items, level_total_items)

func _on_item_collected(_item_type: Variant = null, _collector: Variant = null) -> void:
	var audio = AudioStreamPlayer.new()
	audio.stream = SOM_ITEM
	audio.volume_db = -3.5
	add_child(audio)
	audio.play()
	audio.finished.connect(audio.queue_free)

# --- Sistema de Vida Compartilhada e Morte ---

func take_shared_damage(amount: int = 1) -> void:
	shared_health = clampi(shared_health - amount, 0, shared_max_health)
	print("GameManager: Dano compartilhado sofrido! Vida restante: ", shared_health, "/", shared_max_health)
	
	if has_node("/root/EventBus"):
		EventBus.player_health_changed.emit(active_player, shared_health, shared_max_health)
		
	if shared_health <= 0:
		trigger_game_over()

func heal_shared(amount: int = 1) -> void:
	shared_health = clampi(shared_health + amount, 0, shared_max_health)
	if has_node("/root/EventBus"):
		EventBus.player_health_changed.emit(active_player, shared_health, shared_max_health)

func reset_shared_health() -> void:
	shared_health = shared_max_health
	if has_node("/root/EventBus"):
		EventBus.player_health_changed.emit(active_player, shared_health, shared_max_health)

func _on_level_completed(_level_name: Variant = null) -> void:
	# Vida é automaticamente restaurada ao passar de fase
	reset_shared_health()

func trigger_game_over() -> void:
	print("GameManager: Game Over! Vida compartilhada zerada.")
	
	reset_shared_health()
	
	var current_scene_path: String = ""
	if get_tree() and get_tree().current_scene:
		current_scene_path = get_tree().current_scene.scene_file_path
		
	call_deferred("_deferred_change_or_reload_scene", current_scene_path)

func _deferred_change_or_reload_scene(current_scene_path: String) -> void:
	if not is_inside_tree():
		return
		
	# 1. Define qual checkpoint será carregado quando o jogador apertar uma tecla no Game Over
	if "home" in current_scene_path:
		print("GameManager: Morte na Casa detectada. Checkpoint -> home_1.tscn")
		cena_para_reiniciar = "res://src/levels/home/home_1.tscn"
	elif "telhado" in current_scene_path or "roof" in current_scene_path:
		print("GameManager: Morte no telhado detectada. Checkpoint -> roof_1.tscn")
		cena_para_reiniciar = "res://src/levels/telhado/roof_1.tscn"
	elif "jardim" in current_scene_path or "garden" in current_scene_path:
		print("GameManager: Morte no jardim detectada. Checkpoint -> garden_1.tscn")
		cena_para_reiniciar = "res://src/levels/jardim/garden_1.tscn"
	else:
		print("GameManager: Morte em fase exterior. Checkpoint -> ", current_scene_path)
		cena_para_reiniciar = current_scene_path
		
	# 2. Toca o som de derrota sem cortar
	var audio = AudioStreamPlayer.new()
	audio.stream = SOM_DERROTA
	add_child(audio)
	audio.play()
	audio.finished.connect(audio.queue_free)
	
	# 3. Abre a tela de Game Over
	get_tree().change_scene_to_file("res://src/ui/tela_game_over.tscn")

func reiniciar_apos_gameover() -> void:
	# Restaura a vida máxima e atualiza o HUD
	reset_shared_health()
	
	if cena_para_reiniciar != "":
		get_tree().call_deferred("change_scene_to_file", cena_para_reiniciar)
