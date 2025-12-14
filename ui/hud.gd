extends CanvasLayer
# ═══════════════════════════════════════════════════════════════
# HUD - DIFERENTE PARA CADA MODO DE JUEGO
# ═══════════════════════════════════════════════════════════════
const TEXT_COLOR: Color = Color(0.85, 0.8, 0.7)
const WARNING_COLOR: Color = Color(0.95, 0.7, 0.3)
const DANGER_COLOR: Color = Color(0.95, 0.4, 0.3)
const CRITICAL_COLOR: Color = Color(1.0, 0.25, 0.2)
const STAMINA_COLOR: Color = Color(0.35, 0.75, 0.45)
const HUNTER_COLOR: Color = Color(0.6, 0.3, 0.3)

var time_label: Label
var stamina_bar: ProgressBar
var stamina_container: Control
var notification_container: VBoxContainer
var tension_indicator: Label
var ability_label: Label
var kills_label: Label
var main_container: Control
var current_notifications: Array = []
var is_time_critical: bool = false
var current_game_mode: int = 0
var player_ref = null

func _ready() -> void:
	await get_tree().process_frame
	if GameManager:
		current_game_mode = GameManager.current_game_mode
	_create_hud()
	_connect_events()

func _create_hud() -> void:
	main_container = Control.new()
	main_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(main_container)

	# ═══════════════════════════════════════════════════════════
	# ESQUINA SUPERIOR IZQUIERDA - Tiempo
	# ═══════════════════════════════════════════════════════════
	var top_left = VBoxContainer.new()
	top_left.position = Vector2(20, 20)
	main_container.add_child(top_left)

	time_label = Label.new()
	time_label.text = "10:00"
	time_label.add_theme_font_size_override("font_size", 36)
	time_label.add_theme_color_override("font_color", TEXT_COLOR)
	top_left.add_child(time_label)

	tension_indicator = Label.new()
	tension_indicator.text = ""
	tension_indicator.add_theme_font_size_override("font_size", 14)
	top_left.add_child(tension_indicator)

	# ═══════════════════════════════════════════════════════════
	# ESQUINA INFERIOR IZQUIERDA - Habilidades según modo
	# ═══════════════════════════════════════════════════════════
	var bottom_left = VBoxContainer.new()
	bottom_left.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	bottom_left.position = Vector2(20, -100)
	bottom_left.add_theme_constant_override("separation", 8)
	main_container.add_child(bottom_left)

	ability_label = Label.new()
	ability_label.add_theme_font_size_override("font_size", 14)
	bottom_left.add_child(ability_label)

	if current_game_mode == Config.GameMode.HUNTED:
		ability_label.text = "✝ Crucifijo: 3 usos (Q)"
		ability_label.add_theme_color_override("font_color", Color(0.9, 0.85, 0.6))

		stamina_container = HBoxContainer.new()
		stamina_container.add_theme_constant_override("separation", 8)
		bottom_left.add_child(stamina_container)

		var stamina_lbl = Label.new()
		stamina_lbl.text = "Resistencia"
		stamina_lbl.add_theme_font_size_override("font_size", 12)
		stamina_lbl.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
		stamina_container.add_child(stamina_lbl)

		stamina_bar = ProgressBar.new()
		stamina_bar.max_value = 100
		stamina_bar.value = 100
		stamina_bar.show_percentage = false
		stamina_bar.custom_minimum_size = Vector2(150, 14)
		var fill = StyleBoxFlat.new()
		fill.bg_color = STAMINA_COLOR
		fill.set_corner_radius_all(3)
		stamina_bar.add_theme_stylebox_override("fill", fill)
		var bg = StyleBoxFlat.new()
		bg.bg_color = Color(0.15, 0.15, 0.15, 0.8)
		bg.set_corner_radius_all(3)
		stamina_bar.add_theme_stylebox_override("background", bg)
		stamina_container.add_child(stamina_bar)
	else:
		ability_label.text = "🎭 Transformación (Q)"
		ability_label.add_theme_color_override("font_color", HUNTER_COLOR)

		kills_label = Label.new()
		kills_label.text = "🩸 Muertes: 0"
		kills_label.add_theme_font_size_override("font_size", 16)
		kills_label.add_theme_color_override("font_color", DANGER_COLOR)
		bottom_left.add_child(kills_label)

	# ═══════════════════════════════════════════════════════════
	# DERECHA - Notificaciones
	# ═══════════════════════════════════════════════════════════
	notification_container = VBoxContainer.new()
	notification_container.set_anchors_preset(Control.PRESET_CENTER_RIGHT)
	notification_container.position = Vector2(-320, -100)
	notification_container.custom_minimum_size = Vector2(300, 200)
	notification_container.add_theme_constant_override("separation", 5)
	main_container.add_child(notification_container)

func _connect_events() -> void:
	EventsBus.time_updated.connect(_on_time_updated)
	EventsBus.tension_phase_changed.connect(_on_tension_changed)
	EventsBus.ui_notification.connect(_on_notification)
	EventsBus.player_spawned.connect(_on_player_spawned)

func _on_player_spawned(player: Node) -> void:
	player_ref = player
	if current_game_mode == Config.GameMode.HUNTED:
		if player.has_signal("stamina_changed"):
			player.stamina_changed.connect(_on_stamina_changed)
		if player.has_signal("crucifix_used"):
			player.crucifix_used.connect(_on_crucifix_used)
	else:
		if player.has_signal("prey_killed"):
			player.prey_killed.connect(_on_prey_killed)
		if player.has_signal("disguise_changed"):
			player.disguise_changed.connect(_on_disguise_changed)

func _on_crucifix_used(uses_remaining: int) -> void:
	if uses_remaining > 0:
		ability_label.text = "✝ Crucifijo: " + str(uses_remaining) + " usos (Q)"
	else:
		ability_label.text = "✝ Crucifijo: AGOTADO"
		ability_label.add_theme_color_override("font_color", Color(0.5, 0.4, 0.4))

func _on_prey_killed(_prey: Node) -> void:
	if kills_label and player_ref:
		var kills = player_ref.kills if player_ref.has_method("get") else 0
		kills_label.text = "🩸 Muertes: " + str(kills)

func _on_disguise_changed(disguise_type: String) -> void:
	if disguise_type == "":
		ability_label.text = "🎭 Forma verdadera (Q para disfraz)"
		ability_label.add_theme_color_override("font_color", DANGER_COLOR)
	else:
		ability_label.text = "🎭 Disfrazado: " + disguise_type + " (Q)"
		ability_label.add_theme_color_override("font_color", Color(0.5, 0.7, 0.5))

func _process(_delta: float) -> void:
	_update_time_visual()
	_cleanup_old_notifications()

func _on_time_updated(seconds_remaining: float) -> void:
	var minutes = int(seconds_remaining) / 60
	var secs = int(seconds_remaining) % 60
	time_label.text = "%02d:%02d" % [minutes, secs]
	is_time_critical = seconds_remaining < 60

func _update_time_visual() -> void:
	if not is_instance_valid(time_label):          # ← seguridad
		return
	if is_time_critical:
		var pulse = (sin(Time.get_ticks_msec() / 200.0) + 1) / 2
		time_label.add_theme_color_override("font_color", DANGER_COLOR.lerp(CRITICAL_COLOR, pulse))
	else:
		time_label.add_theme_color_override("font_color", TEXT_COLOR)

func _on_tension_changed(phase: int) -> void:
	if current_game_mode != Config.GameMode.HUNTED:
		tension_indicator.text = ""
		return
	match phase:
		0:
			tension_indicator.text = ""
		1:
			tension_indicator.text = "⚠ Algo no está bien..."
			tension_indicator.add_theme_color_override("font_color", WARNING_COLOR)
		2:
			tension_indicator.text = "👁 ¡Te están cazando!"
			tension_indicator.add_theme_color_override("font_color", DANGER_COLOR)
		3:
			tension_indicator.text = "💀 ¡CORRE!"
			tension_indicator.add_theme_color_override("font_color", CRITICAL_COLOR)

func _on_stamina_changed(current: float, max_val: float) -> void:
	if stamina_bar:
		stamina_bar.max_value = max_val
		stamina_bar.value = current

func _on_notification(message: String, type: String) -> void:
	show_notification(message, type)

func show_notification(text: String, type: String = "info") -> void:
	var notification = _create_notification_panel(text, type)
	notification_container.add_child(notification)
	current_notifications.append({"node": notification, "time": Time.get_ticks_msec(), "duration": 4000})
	notification.modulate.a = 0
	var tween = create_tween()
	tween.tween_property(notification, "modulate:a", 1.0, 0.3)

func _create_notification_panel(text: String, type: String) -> PanelContainer:
	var panel = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.set_corner_radius_all(4)
	style.content_margin_left = 15
	style.content_margin_right = 15
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	match type:
		"warning":
			style.bg_color = Color(0.25, 0.18, 0.1, 0.9)
			style.border_color = WARNING_COLOR
		"danger":
			style.bg_color = Color(0.3, 0.12, 0.1, 0.9)
			style.border_color = DANGER_COLOR
		"bonus":
			style.bg_color = Color(0.12, 0.25, 0.18, 0.9)
			style.border_color = Color(0.4, 0.8, 0.5)
		_:
			style.bg_color = Color(0.15, 0.15, 0.2, 0.9)
			style.border_color = Color(0.5, 0.5, 0.6)
	style.set_border_width_all(1)
	panel.add_theme_stylebox_override("panel", style)

	var label = Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", TEXT_COLOR)
	panel.add_child(label)
	return panel

func _cleanup_old_notifications() -> void:
	var current_time = Time.get_ticks_msec()
	var to_remove: Array = []
	for notif in current_notifications:
		if current_time - notif.time > notif.duration:
			to_remove.append(notif)
	for notif in to_remove:
		if is_instance_valid(notif.node):
			var tween = create_tween()
			tween.tween_property(notif.node, "modulate:a", 0.0, 0.3)
			tween.tween_callback(notif.node.queue_free)
		current_notifications.erase(notif)

func show_hud() -> void:
	visible = true

func hide_hud() -> void:
	visible = false
