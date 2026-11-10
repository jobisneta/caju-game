class_name PlayerHUD
extends CanvasLayer

## Player HUD UI for Caju Game.
## Displays character portrait and hearts (health) in top-left corner
## following the design in inspirations/personagem_UI.png.

const TEXTURE_CORACAO_CHEIO = preload("res://assets/art/ui/coracao_cheio.png")
const TEXTURE_CORACAO_VAZIO = preload("res://assets/art/ui/coracao_vazio.png")
const TEXTURE_PORTRAIT_CAJU = preload("res://assets/art/ui/personagem_caju.png")
const TEXTURE_PORTRAIT_KIKI = preload("res://assets/art/ui/personagem_kiki.png")
const TEXTURE_PORTRAIT_TODY = preload("res://assets/art/ui/personagem_tody.png")

@export var max_health: int = 3
var current_health: int = 3

var portrait: TextureRect
var hearts_container: HBoxContainer
var heart_icons: Array[TextureRect] = []

func _ready() -> void:
	layer = 10 # Acima do jogo e câmera, abaixo do tutorial (100)
	
	if not portrait or heart_icons.is_empty():
		_build_ui()
	
	_connect_events()
	set_health(max_health)

func _build_ui() -> void:
	if get_node_or_null("HUDControl"):
		_bind_existing_nodes()
		return
		
	var root_control = Control.new()
	root_control.name = "HUDControl"
	root_control.set_anchors_preset(Control.PRESET_FULL_RECT)
	root_control.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root_control)
	
	var margin = MarginContainer.new()
	margin.name = "MarginContainer"
	margin.set_anchors_preset(Control.PRESET_TOP_LEFT)
	margin.offset_left = 6
	margin.offset_top = 6
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root_control.add_child(margin)
	
	var hbox = HBoxContainer.new()
	hbox.name = "HBoxContainer"
	hbox.add_theme_constant_override("separation", 4)
	hbox.alignment = BoxContainer.ALIGNMENT_BEGIN
	margin.add_child(hbox)
	
	portrait = TextureRect.new()
	portrait.name = "Portrait"
	portrait.texture = TEXTURE_PORTRAIT_CAJU
	portrait.stretch_mode = TextureRect.STRETCH_KEEP
	portrait.custom_minimum_size = Vector2(25, 25)
	hbox.add_child(portrait)
	
	hearts_container = HBoxContainer.new()
	hearts_container.name = "HeartsContainer"
	hearts_container.add_theme_constant_override("separation", 2)
	hearts_container.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_child(hearts_container)
	
	heart_icons.clear()
	for i in range(max_health):
		var heart = TextureRect.new()
		heart.name = "Heart%d" % (i + 1)
		heart.texture = TEXTURE_CORACAO_CHEIO
		heart.stretch_mode = TextureRect.STRETCH_KEEP
		heart.custom_minimum_size = Vector2(16, 16)
		hearts_container.add_child(heart)
		heart_icons.append(heart)

func _bind_existing_nodes() -> void:
	portrait = get_node_or_null("HUDControl/MarginContainer/HBoxContainer/Portrait")
	hearts_container = get_node_or_null("HUDControl/MarginContainer/HBoxContainer/HeartsContainer")
	heart_icons.clear()
	if hearts_container:
		for child in hearts_container.get_children():
			if child is TextureRect:
				heart_icons.append(child)

func _connect_events() -> void:
	if has_node("/root/EventBus"):
		var bus = get_node("/root/EventBus")
		if not bus.player_swapped.is_connected(_on_player_swapped):
			bus.player_swapped.connect(_on_player_swapped)
		if not bus.player_health_changed.is_connected(_on_player_health_changed):
			bus.player_health_changed.connect(_on_player_health_changed)

func set_health(val: int) -> void:
	current_health = clampi(val, 0, max_health)
	_update_hearts_display()

func take_damage(amount: int = 1) -> void:
	set_health(current_health - amount)

func heal(amount: int = 1) -> void:
	set_health(current_health + amount)

func set_character_portrait(texture: Texture2D) -> void:
	if portrait and texture:
		portrait.texture = texture

func update_for_player(player: CharacterBody2D) -> void:
	if not player:
		return
	if "current_health" in player:
		set_health(player.current_health)
	
	if "portrait_texture" in player and player.portrait_texture != null:
		set_character_portrait(player.portrait_texture)
	elif "character_id" in player:
		if player.character_id == "caju":
			set_character_portrait(TEXTURE_PORTRAIT_CAJU)
		elif player.character_id == "kiki":
			set_character_portrait(TEXTURE_PORTRAIT_KIKI)
		elif player.character_id == "tody":
			set_character_portrait(TEXTURE_PORTRAIT_TODY)

func _update_hearts_display() -> void:
	for i in range(heart_icons.size()):
		if i < current_health:
			heart_icons[i].texture = TEXTURE_CORACAO_CHEIO
		else:
			heart_icons[i].texture = TEXTURE_CORACAO_VAZIO

func _on_player_swapped(active_player: CharacterBody2D) -> void:
	update_for_player(active_player)

func _on_player_health_changed(player: CharacterBody2D, new_health: int, _max_h: int) -> void:
	if has_node("/root/GameManager"):
		var gm = get_node("/root/GameManager")
		if gm.active_player == null or gm.active_player == player:
			set_health(new_health)
	else:
		set_health(new_health)
