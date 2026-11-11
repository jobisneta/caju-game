class_name TutorialPopup
extends CanvasLayer

## Tutorial Popup UI for Caju Game.
## Displays basic controls (WASD, Arrows, Space, Tab).
## Can be reopened anytime via the '?' button at the top-right corner.

const TEXTURE_FUNDO_JANELA = preload("res://assets/art/ui/fundo_janela.png")
const TEXTURE_FUNDO_BOTAO = preload("res://assets/art/ui/fundo_botao.png")
const TEXTURE_BOTAO_AJUDA = preload("res://assets/art/ui/botao_ajuda.png")
const TEXTURE_BOTAO_AJUDA_PRESS = preload("res://assets/art/ui/botao_ajuda_press.png")

var overlay: ColorRect
var center_container: CenterContainer
var panel: PanelContainer
var help_button: TextureButton
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
	
	# Painel do tutorial com textura de fundo temática (9-slice)
	panel = PanelContainer.new()
	panel.name = "Panel"
	var panel_style = StyleBoxTexture.new()
	panel_style.texture = TEXTURE_FUNDO_JANELA
	panel_style.texture_margin_left = 6
	panel_style.texture_margin_top = 6
	panel_style.texture_margin_right = 6
	panel_style.texture_margin_bottom = 6
	panel_style.content_margin_left = 10
	panel_style.content_margin_top = 10
	panel_style.content_margin_right = 10
	panel_style.content_margin_bottom = 10
	panel.add_theme_stylebox_override("panel", panel_style)
	center_container.add_child(panel)
	
	# Layout vertical de conteúdo
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 5)
	panel.add_child(vbox)
	
	# Título com cor contrastante contra o fundo creme
	var title = Label.new()
	title.text = "✦ COMO JOGAR ✦"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 9)
	title.add_theme_color_override("font_color", Color(0.24, 0.16, 0.10))
	vbox.add_child(title)
	
	# Separador sutil com tom terroso
	var hsep = HSeparator.new()
	var sep_style = StyleBoxLine.new()
	sep_style.color = Color(0.65, 0.52, 0.40, 0.6)
	sep_style.thickness = 1
	hsep.add_theme_stylebox_override("separator", sep_style)
	vbox.add_child(hsep)
	
	# Instruções de controle com cor escura legível
	var controls_text = Label.new()
	controls_text.text = "• Mover: W / A / S / D  ou  ← / ↑ / ↓ / →\n• Interagir: P (ou E)\n• Trocar Personagem: TAB"
	controls_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	controls_text.add_theme_font_size_override("font_size", 7)
	controls_text.add_theme_color_override("font_color", Color(0.22, 0.19, 0.18))
	vbox.add_child(controls_text)
	
	# Separador sutil com tom terrosohsep = HSeparator.new()
	hsep = HSeparator.new()
	hsep.add_theme_stylebox_override("separator", sep_style)
	vbox.add_child(hsep)
	
	var objective_text = Label.new()
	objective_text.text = "Colete os pertences e suba a escada\naté o topo para passar de fase!"
	objective_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	objective_text.add_theme_font_size_override("font_size", 7)
	objective_text.add_theme_color_override("font_color", Color(0.22, 0.19, 0.18))
	vbox.add_child(objective_text)
	
	# Botão fechar estilizado com fundo_botao.png
	close_button = Button.new()
	close_button.text = "Entendido"
	close_button.add_theme_font_size_override("font_size", 7)
	close_button.add_theme_color_override("font_color", Color(0.24, 0.16, 0.10))
	close_button.add_theme_color_override("font_hover_color", Color(0.15, 0.10, 0.05))
	close_button.add_theme_color_override("font_pressed_color", Color(0.35, 0.22, 0.12))
	close_button.custom_minimum_size = Vector2(65, 20)
	close_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	
	# Estilo normal para o botão
	var btn_normal = StyleBoxTexture.new()
	btn_normal.texture = TEXTURE_FUNDO_BOTAO
	btn_normal.texture_margin_left = 6
	btn_normal.texture_margin_top = 4
	btn_normal.texture_margin_right = 6
	btn_normal.texture_margin_bottom = 4
	btn_normal.content_margin_top = 2
	btn_normal.content_margin_bottom = 2
	close_button.add_theme_stylebox_override("normal", btn_normal)
	
	# Estilo hover
	var btn_hover = StyleBoxTexture.new()
	btn_hover.texture = TEXTURE_FUNDO_BOTAO
	btn_hover.texture_margin_left = 6
	btn_hover.texture_margin_top = 4
	btn_hover.texture_margin_right = 6
	btn_hover.texture_margin_bottom = 4
	btn_hover.content_margin_top = 2
	btn_hover.content_margin_bottom = 2
	btn_hover.modulate_color = Color(1.08, 1.08, 1.08)
	close_button.add_theme_stylebox_override("hover", btn_hover)
	
	# Estilo pressed
	var btn_pressed = StyleBoxTexture.new()
	btn_pressed.texture = TEXTURE_FUNDO_BOTAO
	btn_pressed.texture_margin_left = 6
	btn_pressed.texture_margin_top = 4
	btn_pressed.texture_margin_right = 6
	btn_pressed.texture_margin_bottom = 4
	btn_pressed.content_margin_top = 3
	btn_pressed.content_margin_bottom = 1
	btn_pressed.modulate_color = Color(0.92, 0.92, 0.92)
	close_button.add_theme_stylebox_override("pressed", btn_pressed)
	
	# Remove borda azul de foco
	close_button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	
	close_button.pressed.connect(_on_close_pressed)
	vbox.add_child(close_button)
	
	# Botão de ajuda pixel-art '?' fixo no canto superior direito usando TextureButton
	help_button = TextureButton.new()
	help_button.name = "HelpButton"
	help_button.texture_normal = TEXTURE_BOTAO_AJUDA
	help_button.texture_pressed = TEXTURE_BOTAO_AJUDA_PRESS
	help_button.texture_hover = TEXTURE_BOTAO_AJUDA
	help_button.custom_minimum_size = Vector2(16, 16)
	help_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
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
	help_button.hide()
	var tree: SceneTree = get_tree()
	if tree:
		tree.paused = true

func _hide_tutorial() -> void:
	overlay.hide()
	center_container.hide()
	help_button.show()
	var tree: SceneTree = get_tree()
	if tree:
		tree.paused = false
