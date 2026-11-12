class_name LevelHome2
extends Node2D

## Second house level controller for Caju Game (Fase 2).
## Environment: House (upper floor / continuation).
## Manages character switching, ladder mechanics, and completion.

const TutorialPopupClass = preload("res://src/ui/tutorial_popup.gd")
const PlayerHUDClass = preload("res://src/ui/player_hud.gd")
const ItemsHUDClass = preload("res://src/ui/items_hud.gd")
const RollingBottleScene = preload("res://src/entities/enemies/glass_bottle/rolling_bottle.tscn")
const TOP_SCREEN_Y_THRESHOLD: float = 16.0

var caju: CharacterBody2D
var items_hud: CanvasLayer

var _caju_at_top: bool = false
var _completed: bool = false
var _bottle_spawn_timer: Timer = null
var _shelf_bottle_positions: Array[Vector2] = []
var _shelf2_spawn_timer: Timer = null
var _shelf2_bottle_positions: Array[Vector2] = []
var _shelf2_active: bool = false

func _ready() -> void:
	if has_node("Caju"):
		caju = get_node("Caju")
		caju.set_camera_limits(0, 920, 0, 180)
		if caju.has_method("make_active"):
			caju.make_active()

	if caju and caju.has_method("make_active"):
		caju.make_active()

	# Instancia o tutorial popup (com botão '?' no canto)
	_setup_tutorial_popup()
	_setup_player_hud()
	_setup_items_hud()
	_setup_bottle_spawner()
	
	if has_node("/root/EventBus"):
		var eb = get_node("/root/EventBus")
		if not eb.item_collected.is_connected(_on_item_collected):
			eb.item_collected.connect(_on_item_collected)

func _setup_tutorial_popup() -> void:
	var popup = TutorialPopupClass.new()
	popup.name = "TutorialPopup"
	add_child(popup)
	popup.call_deferred("_hide_tutorial")

func _setup_player_hud() -> void:
	if not has_node("PlayerHUD"):
		var hud = PlayerHUDClass.new()
		hud.name = "PlayerHUD"
		add_child(hud)

func _setup_items_hud() -> void:
	if has_node("ItemsHUD"):
		items_hud = get_node("ItemsHUD") as CanvasLayer
	else:
		items_hud = ItemsHUDClass.new()
		items_hud.name = "ItemsHUD"
		add_child(items_hud)

	var total_items: int = 1
	var items_container = get_node_or_null("Items")
	if items_container:
		total_items = max(1, items_container.get_child_count())
	
	if has_node("/root/GameManager"):
		GameManager.set_level_items(total_items)
	if items_hud:
		items_hud.setup(total_items, 0)

func _physics_process(_delta: float) -> void:
	if _completed:
		return
	
	if caju and "na_escada" in caju:
		if caju.na_escada and caju.position.y <= TOP_SCREEN_Y_THRESHOLD:
			if has_node("/root/GameManager") and not GameManager.are_all_level_items_collected():
				caju.position.y = TOP_SCREEN_Y_THRESHOLD + 2.0
				_caju_at_top = false
				if items_hud and items_hud.has_method("flash_warning"):
					items_hud.flash_warning()
				return
			_caju_at_top = true
		elif not caju.na_escada or caju.position.y > TOP_SCREEN_Y_THRESHOLD + 20.0:
			_caju_at_top = false
	
	if _caju_at_top:
		_on_level_finished()

func _on_escada_body_entered(body: Node2D) -> void:
	if "na_escada" in body:
		body.na_escada = true

func _on_escada_body_exited(body: Node2D) -> void:
	if "na_escada" in body:
		body.na_escada = false

func _setup_bottle_spawner() -> void:
	# Estante 1 (Garrafas 1 a 4) - rolam para a direita
	_shelf_bottle_positions.clear()
	var shelf_bottle_names: Array[String] = [
		"Environment/GlassBottle1",
		"Environment/GlassBottle2",
		"Environment/GlassBottle3",
		"Environment/GlassBottle4"
	]
	for path in shelf_bottle_names:
		if has_node(path):
			_shelf_bottle_positions.append(get_node(path).global_position)
			
	if _shelf_bottle_positions.is_empty():
		_shelf_bottle_positions = [
			Vector2(255, 95),
			Vector2(238, 117),
			Vector2(220, 117),
			Vector2(216, 95)
		]
		
	_bottle_spawn_timer = Timer.new()
	_bottle_spawn_timer.name = "BottleSpawnTimer"
	_bottle_spawn_timer.one_shot = true
	add_child(_bottle_spawn_timer)
	_bottle_spawn_timer.timeout.connect(_on_bottle_spawn_timer_timeout)
	_schedule_next_bottle_spawn()

	# Estante 2 (Garrafas 5 a 8) - rolam para a esquerda após coletar o item
	_shelf2_bottle_positions.clear()
	var shelf2_bottle_names: Array[String] = [
		"Environment/GlassBottle5",
		"Environment/GlassBottle6",
		"Environment/GlassBottle7",
		"Environment/GlassBottle8"
	]
	for path in shelf2_bottle_names:
		if has_node(path):
			_shelf2_bottle_positions.append(get_node(path).global_position)
			
	if _shelf2_bottle_positions.is_empty():
		_shelf2_bottle_positions = [
			Vector2(707, 95),
			Vector2(689, 117),
			Vector2(723, 117),
			Vector2(724, 95)
		]

	_shelf2_spawn_timer = Timer.new()
	_shelf2_spawn_timer.name = "BottleSpawnTimer2"
	_shelf2_spawn_timer.one_shot = true
	add_child(_shelf2_spawn_timer)
	_shelf2_spawn_timer.timeout.connect(_on_shelf2_spawn_timer_timeout)

func _schedule_next_bottle_spawn() -> void:
	if _completed or not is_instance_valid(_bottle_spawn_timer):
		return
	var wait_time: float = randf_range(1.5, 3.0)
	_bottle_spawn_timer.start(wait_time)

func _on_bottle_spawn_timer_timeout() -> void:
	if _completed:
		return
	_spawn_rolling_bottle()
	_schedule_next_bottle_spawn()

func _spawn_rolling_bottle() -> RollingBottle:
	if _shelf_bottle_positions.is_empty():
		return null
	var spawn_pos: Vector2 = _shelf_bottle_positions.pick_random()
	return spawn_rolling_bottle_at(spawn_pos, 1.0)

func _on_item_collected(_item_name: String, _collector: CharacterBody2D) -> void:
	if _completed or _shelf2_active:
		return
	_shelf2_active = true
	# Delay inicial de 1.0 a 1.5s após a coleta do item antes da primeira garrafa cair
	if is_instance_valid(_shelf2_spawn_timer):
		var initial_delay: float = randf_range(1.0, 1.5)
		_shelf2_spawn_timer.start(initial_delay)

func _schedule_next_shelf2_spawn() -> void:
	if _completed or not _shelf2_active or not is_instance_valid(_shelf2_spawn_timer):
		return
	var wait_time: float = randf_range(2.0, 3.5)
	_shelf2_spawn_timer.start(wait_time)

func _on_shelf2_spawn_timer_timeout() -> void:
	if _completed or not _shelf2_active:
		return
	_spawn_rolling_bottle_shelf2()
	_schedule_next_shelf2_spawn()

func _spawn_rolling_bottle_shelf2() -> RollingBottle:
	if _shelf2_bottle_positions.is_empty():
		return null
	var spawn_pos: Vector2 = _shelf2_bottle_positions.pick_random()
	return spawn_rolling_bottle_at(spawn_pos, -1.0)

func spawn_rolling_bottle_at(pos: Vector2, direction: float = 1.0) -> RollingBottle:
	var bottle: RollingBottle = RollingBottleScene.instantiate() as RollingBottle
	bottle.global_position = pos
	bottle.roll_direction = direction
	var container = get_node_or_null("Environment")
	if container:
		container.add_child(bottle)
	else:
		add_child(bottle)
	return bottle

func _on_level_finished() -> void:
	if _completed:
		return
	_completed = true
	if is_instance_valid(_bottle_spawn_timer):
		_bottle_spawn_timer.stop()
	if is_instance_valid(_shelf2_spawn_timer):
		_shelf2_spawn_timer.stop()
	if has_node("/root/EventBus"):
		var eb = get_node("/root/EventBus")
		if eb.item_collected.is_connected(_on_item_collected):
			eb.item_collected.disconnect(_on_item_collected)
	print("Parabéns! Fase 2 concluída! Transitando para Fase 3...")
	
	if has_node("/root/EventBus"):
		get_node("/root/EventBus").level_completed.emit()
		
	await get_tree().create_timer(0.4).timeout
	get_tree().change_scene_to_file("res://src/levels/home/home_3.tscn")
