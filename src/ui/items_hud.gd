class_name ItemsHUD
extends CanvasLayer

## Items HUD UI for Caju Game.
## Displays stage collection goals below PlayerHUD
## following the design in inspirations/itens_HUD.png.

const DEFAULT_ITEM_TEXTURE = preload("res://assets/art/world/objects/bottle.png")

@export var total_items: int = 1
@export var current_items: int = 0
@export var prompt_text: String = "Colete os seus pertences:"

var label_prompt: Label
var item_icon: TextureRect
var label_count: Label
var _is_flashing: bool = false

func _ready() -> void:
	layer = 10 # Mesma camada da PlayerHUD (abaixo do popup de tutorial que é 100)
	
	if not label_prompt or not label_count:
		_build_ui()
	
	_connect_events()
	_update_display()

func _build_ui() -> void:
	if get_node_or_null("RootControl"):
		_bind_existing_nodes()
		return

	var root_control = Control.new()
	root_control.name = "RootControl"
	root_control.set_anchors_preset(Control.PRESET_FULL_RECT)
	root_control.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root_control)

	var margin = MarginContainer.new()
	margin.name = "MarginContainer"
	margin.set_anchors_preset(Control.PRESET_TOP_LEFT)
	margin.offset_left = 6
	margin.offset_top = 34
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root_control.add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.name = "VBoxContainer"
	vbox.add_theme_constant_override("separation", 2)
	margin.add_child(vbox)

	label_prompt = Label.new()
	label_prompt.name = "LabelPrompt"
	label_prompt.text = prompt_text
	label_prompt.add_theme_font_size_override("font_size", 7)
	label_prompt.add_theme_color_override("font_color", Color(0.12, 0.10, 0.08))
	vbox.add_child(label_prompt)

	var hbox = HBoxContainer.new()
	hbox.name = "ItemRow"
	hbox.add_theme_constant_override("separation", 4)
	hbox.alignment = BoxContainer.ALIGNMENT_BEGIN
	vbox.add_child(hbox)

	item_icon = TextureRect.new()
	item_icon.name = "ItemIcon"
	item_icon.texture = DEFAULT_ITEM_TEXTURE
	item_icon.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	item_icon.custom_minimum_size = Vector2(10, 16)
	hbox.add_child(item_icon)

	label_count = Label.new()
	label_count.name = "LabelCount"
	label_count.text = "%d / %d" % [current_items, total_items]
	label_count.add_theme_font_size_override("font_size", 8)
	label_count.add_theme_color_override("font_color", Color(0.12, 0.10, 0.08))
	hbox.add_child(label_count)

func _bind_existing_nodes() -> void:
	label_prompt = get_node_or_null("RootControl/MarginContainer/VBoxContainer/LabelPrompt")
	item_icon = get_node_or_null("RootControl/MarginContainer/VBoxContainer/ItemRow/ItemIcon")
	label_count = get_node_or_null("RootControl/MarginContainer/VBoxContainer/ItemRow/LabelCount")

func _connect_events() -> void:
	if has_node("/root/EventBus"):
		var bus = get_node("/root/EventBus")
		if not bus.level_items_updated.is_connected(_on_level_items_updated):
			bus.level_items_updated.connect(_on_level_items_updated)

func setup(total: int, current: int = 0, custom_icon: Texture2D = null) -> void:
	total_items = total
	current_items = current
	if custom_icon and item_icon:
		item_icon.texture = custom_icon
	_update_display()

func set_items_count(collected: int, total: int) -> void:
	current_items = collected
	total_items = total
	_update_display()

func _update_display() -> void:
	if label_count:
		label_count.text = "%d / %d" % [current_items, total_items]

func _on_level_items_updated(collected: int, total: int) -> void:
	set_items_count(collected, total)

func flash_warning() -> void:
	if _is_flashing or not label_prompt or not label_count:
		return
	_is_flashing = true
	var alert_color = Color(0.85, 0.15, 0.15)
	var default_color = Color(0.12, 0.10, 0.08)
	var transparent_color = Color(1, 1, 1, 0)

	
	var tween = create_tween()
	tween.tween_property(label_prompt, "theme_override_colors/font_color", alert_color, 0.15)
	tween.parallel().tween_property(label_count, "theme_override_colors/font_color", alert_color, 0.15)
	tween.parallel().tween_property(item_icon, "modulate", alert_color, 0.15)
	tween.tween_property(label_prompt, "theme_override_colors/font_color", default_color, 0.25)
	tween.parallel().tween_property(label_count, "theme_override_colors/font_color", default_color, 0.25)
	tween.parallel().tween_property(item_icon, "modulate", Color.WHITE, 0.25)
	tween.finished.connect(func(): _is_flashing = false)
