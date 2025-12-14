# res://scenes/main.gd
extends Node

# ═══════════════════════════════════════════════════════════════
# ESCENA PRINCIPAL - GAME OVER CORRECTO SEGÚN MODO
# ═══════════════════════════════════════════════════════════════

const MainMenuScene = preload("res://ui/main_menu.gd")
const HUDScene = preload("res://ui/hud.gd")
const PauseMenuScene = preload("res://ui/pause_menu.gd")

var current_menu: Control = null
var current_hud: CanvasLayer = null
var game_over_screen: Control = null

var is_in_game: bool = false

func _ready() -> void:
	print("[MAIN] Escena principal cargada")
	
	if GameManager:
		GameManager.state_changed.connect(_on_game_state_changed)
		GameManager.game_ready.connect(_on_game_ready)
	
	EventsBus.game_ended.connect(_on_game_ended)
	
	_show_main_menu()

func _show_main_menu() -> void:
	_cleanup_all_ui()
	
	current_menu = Control.new()
	current_menu.set_script(MainMenuScene)
	current_menu.name = "MainMenu"
	add_child(current_menu)
	
	is_in_game = false

func _show_hud() -> void:
	if current_hud:
		return
	
	current_hud = CanvasLayer.new()
	current_hud.set_script(HUDScene)
	current_hud.name = "HUD"
	current_hud.layer = 10
	add_child(current_hud)

func _hide_hud() -> void:
	if current_hud:
		current_hud.queue_free()
		current_hud = null

func _cleanup_all_ui() -> void:
	if current_menu:
		current_menu.queue_free()
		current_menu = null
	if game_over_screen:
		game_over_screen.queue_free()
		game_over_screen = null

func _on_game_state_changed(new_state: int) -> void:
	match new_state:
		1:  # MAIN_MENU
			_show_main_menu()
			_hide_hud()
		2:  # LOADING
			_cleanup_all_ui()
		3:  # PLAYING
			_show_hud()
			is_in_game = true
		4:  # PAUSED
			_show_pause_menu()

func _on_game_ready() -> void:
	print("[MAIN] Juego listo")

func _on_game_ended(victory: bool, reason: String) -> void:
	_hide_hud()
	_show_game_over_screen(victory, reason)

func _show_pause_menu() -> void:
	var pause = Control.new()
	pause.set_script(PauseMenuScene)
	pause.name = "PauseMenu"
	add_child(pause)

func _show_game_over_screen(victory: bool, reason: String) -> void:
	if game_over_screen:
		game_over_screen.queue_free()
	
	get_tree().paused = true
	
	game_over_screen = Control.new()
	game_over_screen.name = "GameOverScreen"
	game_over_screen.set_anchors_preset(Control.PRESET_FULL_RECT)
	game_over_screen.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(game_over_screen)
	
	# Fondo
	var bg = ColorRect.new()
	bg.color = Color(0, 0, 0, 0.88)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	game_over_screen.add_child(bg)
	
	# Centro
	var center = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	game_over_screen.add_child(center)
	
	# Panel
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(420, 0)
	
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.06, 0.06, 0.08, 0.98)
	panel_style.border_color = Color(0.4, 0.6, 0.3) if victory else Color(0.6, 0.3, 0.25)
	panel_style.set_border_width_all(3)
	panel_style.set_corner_radius_all(12)
	panel_style.content_margin_left = 45
	panel_style.content_margin_right = 45
	panel_style.content_margin_top = 40
	panel_style.content_margin_bottom = 40
	panel.add_theme_stylebox_override("panel", panel_style)
	center.add_child(panel)
	
	var container = VBoxContainer.new()
	container.add_theme_constant_override("separation", 18)
	panel.add_child(container)
	
	# ═══════════════════════════════════════════════════════════
	# DETERMINAR TÍTULO E ICONO SEGÚN MODO Y RESULTADO
	# ═══════════════════════════════════════════════════════════
	var icon_text: String
	var title_text: String
	var title_color: Color
	
	var game_mode = Config.GameMode.HUNTED
	if GameManager:
		game_mode = GameManager.current_game_mode
	
	if victory:
		if game_mode == Config.GameMode.HUNTED:
			icon_text = "🌅"
			title_text = "¡SOBREVIVISTE!"
			title_color = Color(0.4, 0.8, 0.4)
		else:
			icon_text = "🩸"
			title_text = "¡CACERÍA EXITOSA!"
			title_color = Color(0.8, 0.3, 0.3)
	else:
		if game_mode == Config.GameMode.HUNTED:
			icon_text = "💀"
			title_text = "HAS MUERTO"
			title_color = Color(0.9, 0.3, 0.3)
		else:
			icon_text = "🏃"
			title_text = "LA PRESA ESCAPÓ"
			title_color = Color(0.9, 0.6, 0.3)
	
	# Icono
	var icon = Label.new()
	icon.text = icon_text
	icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon.add_theme_font_size_override("font_size", 72)
	container.add_child(icon)
	
	# Título
	var title = Label.new()
	title.text = title_text
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 34)
	title.add_theme_color_override("font_color", title_color)
	container.add_child(title)
	
	# Razón
	var reason_lbl = Label.new()
	reason_lbl.text = reason
	reason_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	reason_lbl.add_theme_font_size_override("font_size", 15)
	reason_lbl.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	reason_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	reason_lbl.custom_minimum_size.x = 350
	container.add_child(reason_lbl)
	
	# Separador
	var sep = Control.new()
	sep.custom_minimum_size = Vector2(0, 12)
	container.add_child(sep)
	
	# Botones
	var buttons = VBoxContainer.new()
	buttons.add_theme_constant_override("separation", 10)
	container.add_child(buttons)
	
	_create_go_button(buttons, "🔄 REINTENTAR", _on_retry)
	_create_go_button(buttons, "🏠 MENÚ PRINCIPAL", _on_menu)

func _create_go_button(parent: Node, text: String, callback: Callable) -> void:
	var btn = Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(280, 50)
	
	var style_n = StyleBoxFlat.new()
	style_n.bg_color = Color(0.12, 0.1, 0.1, 0.9)
	style_n.border_color = Color(0.5, 0.35, 0.25)
	style_n.set_border_width_all(2)
	style_n.set_corner_radius_all(6)
	btn.add_theme_stylebox_override("normal", style_n)
	
	var style_h = StyleBoxFlat.new()
	style_h.bg_color = Color(0.2, 0.14, 0.12, 0.95)
	style_h.border_color = Color(0.7, 0.5, 0.35)
	style_h.set_border_width_all(2)
	style_h.set_corner_radius_all(6)
	btn.add_theme_stylebox_override("hover", style_h)
	
	btn.add_theme_color_override("font_color", Color(0.85, 0.8, 0.7))
	btn.add_theme_color_override("font_hover_color", Color(1, 0.9, 0.7))
	btn.add_theme_font_size_override("font_size", 18)
	
	btn.pressed.connect(callback)
	parent.add_child(btn)

func _on_retry() -> void:
	get_tree().paused = false
	if game_over_screen:
		game_over_screen.queue_free()
		game_over_screen = null
	if GameManager:
		GameManager.restart_game()

func _on_menu() -> void:
	get_tree().paused = false
	if game_over_screen:
		game_over_screen.queue_free()
		game_over_screen = null
	if GameManager:
		GameManager.return_to_menu()
