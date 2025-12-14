# res://ui/main_menu.gd
extends Control

# ═══════════════════════════════════════════════════════════════
# MENÚ PRINCIPAL - PERFECTAMENTE CENTRADO
# ═══════════════════════════════════════════════════════════════

const BG_COLOR: Color = Color(0.015, 0.018, 0.025)
const TEXT_COLOR: Color = Color(0.75, 0.7, 0.6)
const ACCENT_COLOR: Color = Color(0.65, 0.35, 0.22)
const HOVER_COLOR: Color = Color(0.85, 0.55, 0.35)
const DISABLED_COLOR: Color = Color(0.35, 0.32, 0.28)

var background: ColorRect
var fog_overlay: ColorRect
var title_label: Label
var subtitle_label: Label

func _ready() -> void:
	_create_ui()
	_animate_entrance()

func _create_ui() -> void:
	# ═══════════════════════════════════════════════════════════
	# FORZAR PANTALLA COMPLETA
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
	
	# Fondo
	background = ColorRect.new()
	background.color = BG_COLOR
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	
	# Niebla animada
	fog_overlay = ColorRect.new()
	fog_overlay.color = Color(0.05, 0.06, 0.1, 0.25)
	fog_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(fog_overlay)
	
	# ═══════════════════════════════════════════════════════════
	# CONTENEDOR PRINCIPAL - CENTRADO ABSOLUTO
	# ═══════════════════════════════════════════════════════════
	var main_center = CenterContainer.new()
	main_center.set_anchors_preset(Control.PRESET_FULL_RECT)
	main_center.anchor_left = 0
	main_center.anchor_top = 0
	main_center.anchor_right = 1
	main_center.anchor_bottom = 1
	main_center.offset_left = 0
	main_center.offset_top = 0
	main_center.offset_right = 0
	main_center.offset_bottom = 0
	add_child(main_center)
	
	# Panel de contenido
	var content_panel = VBoxContainer.new()
	content_panel.add_theme_constant_override("separation", 12)
	main_center.add_child(content_panel)
	
	# ═══════════════════════════════════════════════════════════
	# TÍTULO Y SUBTÍTULO
	# ═══════════════════════════════════════════════════════════
	title_label = Label.new()
	title_label.text = "🌙 SKINWALKER HOLLOW 🌙"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 48)
	title_label.add_theme_color_override("font_color", TEXT_COLOR)
	content_panel.add_child(title_label)
	
	subtitle_label = Label.new()
	subtitle_label.text = "En las montañas Apalaches, algo te observa..."
	subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle_label.add_theme_font_size_override("font_size", 16)
	subtitle_label.add_theme_color_override("font_color", ACCENT_COLOR)
	content_panel.add_child(subtitle_label)
	
	# Espaciador
	var spacer1 = Control.new()
	spacer1.custom_minimum_size = Vector2(0, 35)
	content_panel.add_child(spacer1)
	
	# ═══════════════════════════════════════════════════════════
	# BOTONES DE MODO DE JUEGO
	# ═══════════════════════════════════════════════════════════
	var modes_label = Label.new()
	modes_label.text = "— SELECCIONA TU DESTINO —"
	modes_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	modes_label.add_theme_font_size_override("font_size", 14)
	modes_label.add_theme_color_override("font_color", DISABLED_COLOR)
	content_panel.add_child(modes_label)
	
	var spacer2 = Control.new()
	spacer2.custom_minimum_size = Vector2(0, 10)
	content_panel.add_child(spacer2)
	
	# Contenedor de botones principales
	var buttons_box = VBoxContainer.new()
	buttons_box.add_theme_constant_override("separation", 8)
	content_panel.add_child(buttons_box)
	
	_create_mode_button(buttons_box, "🎯 MODO CAZADO", "Sobrevive la noche. Escapa del pueblo.", "hunted")
	_create_mode_button(buttons_box, "👹 MODO CAZADOR", "Conviértete en el Cambiapieles. Caza.", "hunter")
	
	# Separador visual
	var sep_container = HBoxContainer.new()
	sep_container.alignment = BoxContainer.ALIGNMENT_CENTER
	content_panel.add_child(sep_container)
	
	var sep_line = HSeparator.new()
	sep_line.custom_minimum_size = Vector2(200, 20)
	sep_container.add_child(sep_line)
	
	# Botones secundarios
	var secondary_box = VBoxContainer.new()
	secondary_box.add_theme_constant_override("separation", 8)
	content_panel.add_child(secondary_box)
	
	_create_secondary_button(secondary_box, "⚙️ Opciones", "options")
	_create_secondary_button(secondary_box, "🚪 Salir", "quit")
	
	# ═══════════════════════════════════════════════════════════
	# VERSIÓN Y CONTROLES
	# ═══════════════════════════════════════════════════════════
	var version_label = Label.new()
	version_label.text = "v0.2.0 - Desarrollo"
	version_label.add_theme_font_size_override("font_size", 11)
	version_label.add_theme_color_override("font_color", Color(0.3, 0.3, 0.3))
	version_label.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	version_label.offset_right = -15
	version_label.offset_bottom = -10
	add_child(version_label)
	
	var controls_label = Label.new()
	controls_label.text = "WASD: Mover | SHIFT: Correr | Q: Habilidad | E: Interactuar | ESC: Pausa"
	controls_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	controls_label.add_theme_font_size_override("font_size", 11)
	controls_label.add_theme_color_override("font_color", Color(0.35, 0.35, 0.35))
	controls_label.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	controls_label.offset_bottom = -35
	add_child(controls_label)

func _create_mode_button(parent: Node, text: String, description: String, action: String) -> void:
	var container = VBoxContainer.new()
	container.add_theme_constant_override("separation", 4)
	parent.add_child(container)
	
	var button = Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(340, 55)
	button.set_meta("action", action)
	
	var style_normal = StyleBoxFlat.new()
	style_normal.bg_color = Color(0.1, 0.08, 0.07, 0.85)
	style_normal.border_color = ACCENT_COLOR.darkened(0.1)
	style_normal.set_border_width_all(2)
	style_normal.set_corner_radius_all(6)
	button.add_theme_stylebox_override("normal", style_normal)
	
	var style_hover = StyleBoxFlat.new()
	style_hover.bg_color = Color(0.16, 0.1, 0.08, 0.95)
	style_hover.border_color = HOVER_COLOR
	style_hover.set_border_width_all(2)
	style_hover.set_corner_radius_all(6)
	button.add_theme_stylebox_override("hover", style_hover)
	
	var style_pressed = StyleBoxFlat.new()
	style_pressed.bg_color = Color(0.22, 0.12, 0.08, 1.0)
	style_pressed.border_color = HOVER_COLOR.lightened(0.2)
	style_pressed.set_border_width_all(3)
	style_pressed.set_corner_radius_all(6)
	button.add_theme_stylebox_override("pressed", style_pressed)
	
	button.add_theme_color_override("font_color", TEXT_COLOR)
	button.add_theme_color_override("font_hover_color", HOVER_COLOR)
	button.add_theme_font_size_override("font_size", 20)
	
	button.pressed.connect(_on_button_pressed.bind(action))
	container.add_child(button)
	
	var desc_label = Label.new()
	desc_label.text = description
	desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_label.add_theme_font_size_override("font_size", 12)
	desc_label.add_theme_color_override("font_color", DISABLED_COLOR)
	container.add_child(desc_label)

func _create_secondary_button(parent: Node, text: String, action: String) -> void:
	var button = Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(200, 40)
	button.flat = true
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.08, 0.1, 0.6)
	style.border_color = Color(0.3, 0.28, 0.25)
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	button.add_theme_stylebox_override("normal", style)
	
	var style_hover = StyleBoxFlat.new()
	style_hover.bg_color = Color(0.12, 0.1, 0.12, 0.8)
	style_hover.border_color = ACCENT_COLOR
	style_hover.set_border_width_all(1)
	style_hover.set_corner_radius_all(4)
	button.add_theme_stylebox_override("hover", style_hover)
	
	button.add_theme_color_override("font_color", DISABLED_COLOR)
	button.add_theme_color_override("font_hover_color", TEXT_COLOR)
	button.add_theme_font_size_override("font_size", 15)
	
	button.pressed.connect(_on_button_pressed.bind(action))
	parent.add_child(button)

func _animate_entrance() -> void:
	title_label.modulate.a = 0
	subtitle_label.modulate.a = 0
	
	var tween = create_tween()
	tween.tween_property(title_label, "modulate:a", 1.0, 1.2)
	tween.parallel().tween_property(subtitle_label, "modulate:a", 1.0, 1.5).set_delay(0.3)
	
	# Animación de niebla
	var fog_tween = create_tween()
	fog_tween.set_loops()
	fog_tween.tween_property(fog_overlay, "modulate:a", 0.7, 5.0)
	fog_tween.tween_property(fog_overlay, "modulate:a", 0.4, 5.0)

func _on_button_pressed(action: String) -> void:
	match action:
		"hunted":
			_start_game(Config.GameMode.HUNTED)
		"hunter":
			_start_game(Config.GameMode.HUNTER)
		"options":
			EventsBus.emit_notification("Opciones próximamente", "info")
		"quit":
			_quit_game()

func _start_game(mode: int) -> void:
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.4)
	await tween.finished
	
	if GameManager:
		GameManager.start_new_game(mode)
	
	queue_free()

func _quit_game() -> void:
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	await tween.finished
	get_tree().quit()
