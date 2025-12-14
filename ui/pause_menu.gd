# res://ui/pause_menu.gd
extends Control

# ═══════════════════════════════════════════════════════════════
# MENÚ DE PAUSA - CENTRADO CORRECTAMENTE
# ═══════════════════════════════════════════════════════════════

const BG_COLOR: Color = Color(0.01, 0.01, 0.02, 0.92)
const TEXT_COLOR: Color = Color(0.75, 0.7, 0.6)
const ACCENT_COLOR: Color = Color(0.65, 0.35, 0.25)

func _ready() -> void:
	_create_ui()
	get_tree().paused = true
	process_mode = Node.PROCESS_MODE_ALWAYS

func _create_ui() -> void:
	# ═══════════════════════════════════════════════════════════
	# PANTALLA COMPLETA
	# ═══════════════════════════════════════════════════════════
	set_anchors_preset(Control.PRESET_FULL_RECT)
	anchor_left = 0
	anchor_top = 0
	anchor_right = 1
	anchor_bottom = 1
	offset_left = 0
	offset_top = 0
	offset_right = 0
	offset_bottom = 0
	
	# Fondo oscuro que cubre todo
	var background = ColorRect.new()
	background.color = BG_COLOR
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	
	# ═══════════════════════════════════════════════════════════
	# CENTRO ABSOLUTO
	# ═══════════════════════════════════════════════════════════
	var center = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.anchor_left = 0
	center.anchor_top = 0
	center.anchor_right = 1
	center.anchor_bottom = 1
	add_child(center)
	
	# Panel
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(320, 0)
	
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.06, 0.06, 0.08, 0.98)
	panel_style.border_color = ACCENT_COLOR
	panel_style.set_border_width_all(2)
	panel_style.set_corner_radius_all(10)
	panel_style.content_margin_left = 40
	panel_style.content_margin_right = 40
	panel_style.content_margin_top = 35
	panel_style.content_margin_bottom = 35
	panel.add_theme_stylebox_override("panel", panel_style)
	center.add_child(panel)
	
	# Contenido
	var content = VBoxContainer.new()
	content.add_theme_constant_override("separation", 20)
	panel.add_child(content)
	
	# Título
	var title = Label.new()
	title.text = "⏸ PAUSA"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 36)
	title.add_theme_color_override("font_color", TEXT_COLOR)
	content.add_child(title)
	
	# Separador
	var sep = HSeparator.new()
	sep.add_theme_color_override("separator_color", ACCENT_COLOR.darkened(0.4))
	content.add_child(sep)
	
	# Botones
	var buttons = VBoxContainer.new()
	buttons.add_theme_constant_override("separation", 12)
	content.add_child(buttons)
	
	_create_button(buttons, "▶ CONTINUAR", _on_continue)
	_create_button(buttons, "🏠 MENÚ PRINCIPAL", _on_menu)
	_create_button(buttons, "🚪 SALIR", _on_quit)

func _create_button(parent: Node, text: String, callback: Callable) -> void:
	var btn = Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(240, 48)
	
	var style_n = StyleBoxFlat.new()
	style_n.bg_color = Color(0.1, 0.08, 0.08, 0.9)
	style_n.border_color = ACCENT_COLOR.darkened(0.2)
	style_n.set_border_width_all(1)
	style_n.set_corner_radius_all(6)
	btn.add_theme_stylebox_override("normal", style_n)
	
	var style_h = StyleBoxFlat.new()
	style_h.bg_color = Color(0.18, 0.12, 0.1, 0.95)
	style_h.border_color = ACCENT_COLOR
	style_h.set_border_width_all(2)
	style_h.set_corner_radius_all(6)
	btn.add_theme_stylebox_override("hover", style_h)
	
	var style_p = StyleBoxFlat.new()
	style_p.bg_color = Color(0.25, 0.15, 0.12, 1.0)
	style_p.border_color = ACCENT_COLOR.lightened(0.2)
	style_p.set_border_width_all(2)
	style_p.set_corner_radius_all(6)
	btn.add_theme_stylebox_override("pressed", style_p)
	
	btn.add_theme_color_override("font_color", TEXT_COLOR)
	btn.add_theme_color_override("font_hover_color", Color(1.0, 0.85, 0.65))
	btn.add_theme_font_size_override("font_size", 17)
	
	btn.pressed.connect(callback)
	parent.add_child(btn)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		_on_continue()
		get_viewport().set_input_as_handled()

func _on_continue() -> void:
	get_tree().paused = false
	EventsBus.game_paused.emit(false)
	queue_free()

func _on_menu() -> void:
	get_tree().paused = false
	if GameManager:
		GameManager.return_to_menu()
	queue_free()

func _on_quit() -> void:
	get_tree().quit()
