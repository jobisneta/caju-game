class_name TutorialPopup
extends CanvasLayer

## Tutorial Popup UI for Caju Game.
## Displays basic controls (WASD, Arrows, Space, Tab).
## Can be reopened anytime via the '?' button at the top-right corner.

var overlay: ColorRect
var center_container: CenterContainer
var panel: PanelContainer
var help_button: Button
var close_button: Button

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 100 # Garante que fica acima de qualquer elemento do jogo
	
	_build_ui()
	_show_tutorial()

func _build_ui() -> void:
	# Raiz Control que ocupa toda a tela de 320x180
	var root_control = Control.new()
	root_control.name = "TutorialRoot"
	root_control.set_anchors_preset(Control.PRESET_FULL_RECT)
	root_control.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root_control)
	
	# Fundo escuro semi-transparente quando o tutorial está aberto
	overlay = ColorRect.new()
	overlay.name = "Overlay"
	overlay.color = Color(0, 0, 0, 0.65)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	root_control.add_child(overlay)
	
	# Container centralizado para o painel de tutorial
	center_container = CenterContainer.new()
	center_container.name = "CenterContainer"
	center_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	center_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root_control.add_child(center_container)
	
	# Painel do tutorial com estilo limpo
	panel = PanelContainer.new()
	panel.name = "Panel"
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.12, 0.12, 0.16, 0.95)
	panel_style.border_color = Color(0.85, 0.65, 0.2, 1.0) # Borda dourada sutil
	panel_style.set_border_width_all(1)
	panel_style.set_corner_radius_all(3)
	panel_style.set_content_margin_all(8)
	panel.add_theme_stylebox_override("panel", panel_style)
	center_container.add_child(panel)
	
	# Layout vertical de conteúdo
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 5)
	panel.add_child(vbox)
	
	# Título
	var title = Label.new()
	title.text = "✦ COMO JOGAR ✦"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 9)
	title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	vbox.add_child(title)
	
	# Separador sutil
	var hsep = HSeparator.new()
	vbox.add_child(hsep)
	
	# Instruções de controle
	var controls_text = Label.new()
	controls_text.text = "• Mover: A / D  ou  ← / →\n• Pular: W, Espaço ou ↑\n• Escada: W / S  ou  ↑ / ↓\n• Trocar Personagem: TAB\n\nSuba a escada até o topo com\nambos para passar de fase!"
	controls_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	controls_text.add_theme_font_size_override("font_size", 7)
	controls_text.add_theme_color_override("font_color", Color(0.92, 0.92, 0.92))
	vbox.add_child(controls_text)
	
	# Botão fechar
	close_button = Button.new()
	close_button.text = "Entendido"
	close_button.add_theme_font_size_override("font_size", 7)
	close_button.custom_minimum_size = Vector2(60, 14)
	close_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	close_button.pressed.connect(_on_close_pressed)
	vbox.add_child(close_button)
	
	# Botão de ajuda '?' fixo no canto superior direito
	help_button = Button.new()
	help_button.name = "HelpButton"
	help_button.text = "?"
	help_button.add_theme_font_size_override("font_size", 8)
	help_button.custom_minimum_size = Vector2(16, 16)
	help_button.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	help_button.anchor_left = 1.0
	help_button.anchor_top = 0.0
	help_button.anchor_right = 1.0
	help_button.anchor_bottom = 0.0
	help_button.offset_left = -22
	help_button.offset_top = 6
	help_button.offset_right = -6
	help_button.offset_bottom = 22
	help_button.pressed.connect(_on_help_pressed)
	root_control.add_child(help_button)

func _on_help_pressed() -> void:
	_show_tutorial()

func _on_close_pressed() -> void:
	_hide_tutorial()

func _show_tutorial() -> void:
	overlay.show()
	center_container.show()
	help_button.hide() # Oculta o '?' enquanto o popup estiver aberto
	get_tree().paused = true

func _hide_tutorial() -> void:
	overlay.hide()
	center_container.hide()
	help_button.show() # Mostra o '?' no canto da tela para ver novamente
	get_tree().paused = false
