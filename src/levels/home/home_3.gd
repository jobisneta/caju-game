class_name LevelHome3
extends Node2D

## Third house level controller for Caju Game (Fase 3 - Salão das Cortinas).
## Environment: House (hallway with swing curtains).
## Mode: Solo Caju. Manages camera limits, curtain swing, and transition to Rooftop (roof_1).

const TutorialPopupClass = preload("res://src/ui/tutorial_popup.gd")
const PlayerHUDClass = preload("res://src/ui/player_hud.gd")
const ItemsHUDClass = preload("res://src/ui/items_hud.gd")
const RollingBottleScene = preload("res://src/entities/enemies/glass_bottle/rolling_bottle.tscn")

const EXIT_X_THRESHOLD: float = 1220.0
const BOTTLE_BREAK_MIN_X: float = 570.0
const BOTTLE_SPAWN_MIN_INTERVAL: float = 1.2
const BOTTLE_SPAWN_MAX_INTERVAL: float = 2.0

@export var caju: CharacterBody2D

var items_hud: CanvasLayer
var _completed: bool = false
var _bottle_spawn_timer: Timer = null
var _shelf_bottle_positions: Array[Vector2] = []

func _ready() -> void:
	if has_node("Caju"):
		caju = get_node("Caju")
		caju.set_camera_limits(0, 1120, 0, 180)
		if caju.has_method("make_active"):
			caju.make_active()
	else:
		push_error("LevelHome3: Caju não foi encontrado!")
		
	_setup_tutorial_popup()
	_setup_player_hud()
	_setup_items_hud()
	_setup_crate_link()
	_setup_bottle_spawner()
	_setup_exit_window()
	_setup_window_light_pulse()

func _setup_tutorial_popup() -> void:
	if not has_node("TutorialPopup"):
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
	var items_container: Node = get_node_or_null("Items")
	if items_container:
		total_items = max(1, items_container.get_child_count())
	
	if has_node("/root/GameManager"):
		GameManager.set_level_items(total_items)
	if items_hud:
		items_hud.setup(total_items, 0)

func _setup_crate_link() -> void:
	var caixa1: Node = get_node_or_null("CaixaPos1")
	var caixa2: StaticBody2D = get_node_or_null("CaixaPos2") as StaticBody2D
	var hidden_bottle: Node2D = get_node_or_null("Items/Bottle") as Node2D
	if caixa1 and caixa2:
		if "target_box" in caixa1:
			caixa1.target_box = caixa2
		if "requires_right_side" in caixa1:
			caixa1.requires_right_side = false
		if "requires_left_side" in caixa1:
			caixa1.requires_left_side = true
		if "break_on_land" in caixa1:
			caixa1.break_on_land = true
		if "reveal_item" in caixa1 and hidden_bottle:
			caixa1.reveal_item = hidden_bottle

func _setup_bottle_spawner() -> void:
	_shelf_bottle_positions.clear()
	var shelf_bottle_names: Array[String] = [
		"GlassBottle1",
		"GlassBottle2",
		"GlassBottle3",
		"GlassBottle4",
		"GlassBottle5"
	]
	for bottle_name in shelf_bottle_names:
		if has_node(bottle_name):
			_shelf_bottle_positions.append(get_node(bottle_name).global_position)
	
	if _shelf_bottle_positions.is_empty():
		_shelf_bottle_positions = [
			Vector2(888, 95),
			Vector2(905, 117),
			Vector2(871, 117),
			Vector2(869, 95),
			Vector2(908, 139)
		]
	
	_bottle_spawn_timer = Timer.new()
	_bottle_spawn_timer.name = "BottleSpawnTimer"
	_bottle_spawn_timer.one_shot = true
	add_child(_bottle_spawn_timer)
	_bottle_spawn_timer.timeout.connect(_on_bottle_spawn_timer_timeout)
	_schedule_next_bottle_spawn()

func _setup_exit_window() -> void:
	var area_saida: Area2D = get_node_or_null("JanelaSaida/AreaSaida") as Area2D
	if area_saida:
		area_saida.collision_layer = 0
		area_saida.collision_mask = 2
		if not area_saida.body_entered.is_connected(_on_janela_saida_body_entered):
			area_saida.body_entered.connect(_on_janela_saida_body_entered)

func _setup_window_light_pulse() -> void:
	var luz: Polygon2D = get_node_or_null("LuzJanelaSaida") as Polygon2D
	if luz and is_inside_tree():
		var tween: Tween = create_tween().set_loops()
		tween.tween_property(luz, "modulate:a", 0.80, 1.8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tween.tween_property(luz, "modulate:a", 1.0, 1.8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _on_janela_saida_body_entered(body: Node2D) -> void:
	if _completed or not body or not body.is_in_group("player"):
		return
	if has_node("/root/GameManager") and not GameManager.are_all_level_items_collected():
		if items_hud and items_hud.has_method("flash_warning"):
			items_hud.flash_warning()
		return
	_on_level_finished()

func _schedule_next_bottle_spawn() -> void:
	if _completed or not is_instance_valid(_bottle_spawn_timer):
		return
	var wait_time: float = randf_range(BOTTLE_SPAWN_MIN_INTERVAL, BOTTLE_SPAWN_MAX_INTERVAL)
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
	return spawn_rolling_bottle_at(spawn_pos, -1.0, BOTTLE_BREAK_MIN_X)

func spawn_rolling_bottle_at(pos: Vector2, direction: float = -1.0, min_x: float = BOTTLE_BREAK_MIN_X) -> RollingBottle:
	var bottle: RollingBottle = RollingBottleScene.instantiate() as RollingBottle
	bottle.global_position = pos
	bottle.roll_direction = direction
	bottle.min_x_position = min_x
	add_child(bottle)
	return bottle

func _physics_process(_delta: float) -> void:
	if _completed:
		return
	if caju and caju.position.x >= EXIT_X_THRESHOLD:
		if has_node("/root/GameManager") and not GameManager.are_all_level_items_collected():
			caju.position.x = EXIT_X_THRESHOLD - 2.0
			if items_hud and items_hud.has_method("flash_warning"):
				items_hud.flash_warning()
			return
		_on_level_finished()

func _on_level_finished() -> void:
	if _completed:
		return
	_completed = true
	if is_instance_valid(_bottle_spawn_timer):
		_bottle_spawn_timer.stop()
	print("Parabéns! Fase 3 concluída! Transitando para o Telhado (roof_1)...")
	
	if has_node("/root/EventBus"):
		get_node("/root/EventBus").level_completed.emit()
		
	await get_tree().create_timer(0.4).timeout
	get_tree().change_scene_to_file("res://src/levels/telhado/roof_1.tscn")
