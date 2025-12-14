# res://rendering/isometric_camera.gd
extends Camera3D
class_name IsometricCamera

# ═══════════════════════════════════════════════════════════════
# CÁMARA ISOMÉTRICA - MÁS BAJA + ZOOM CON RUEDA DEL MOUSE
# ═══════════════════════════════════════════════════════════════

@export var target: Node3D = null
@export var follow_speed: float = 6.0
@export var offset: Vector3 = Vector3(6, 8, 6)  # Más baja (antes 10, 15, 10)

# --- ZOOM ---
@export var zoom_level: float = 1.0
@export var min_zoom: float = 0.6
@export var max_zoom: float = 2.0
@export var zoom_speed: float = 0.1
@export var zoom_smoothness: float = 8.0

var target_zoom: float = 1.0
var base_size: float = 15.0  # Tamaño base más pequeño para vista más cercana

# --- EFECTOS DE TENSIÓN ---
var tension_shake_intensity: float = 0.0
var base_offset: Vector3

# --- ESTADO ---
var is_locked: bool = false

func _ready() -> void:
	projection = PROJECTION_ORTHOGONAL
	size = base_size
	rotation_degrees = Vector3(-35.264, 45, 0)
	
	base_offset = offset
	target_zoom = zoom_level
	
	EventsBus.tension_phase_changed.connect(_on_tension_changed)
	EventsBus.horror_event_triggered.connect(_on_horror_event)

func _process(delta: float) -> void:
	if target and is_instance_valid(target) and not is_locked:
		_follow_target(delta)
	
	_handle_zoom(delta)
	_apply_tension_effects(delta)

func _follow_target(delta: float) -> void:
	var target_position = target.global_position + offset * zoom_level
	global_position = global_position.lerp(target_position, follow_speed * delta)

func _handle_zoom(delta: float) -> void:
	# Suavizar el zoom
	zoom_level = lerp(zoom_level, target_zoom, zoom_smoothness * delta)
	size = base_size * zoom_level

func _input(event: InputEvent) -> void:
	# ═══════════════════════════════════════════════════════════
	# ZOOM CON RUEDA DEL MOUSE (como LoL)
	# ═══════════════════════════════════════════════════════════
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			# Acercar (zoom in)
			target_zoom = clamp(target_zoom - zoom_speed, min_zoom, max_zoom)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			# Alejar (zoom out)
			target_zoom = clamp(target_zoom + zoom_speed, min_zoom, max_zoom)
	
	# También con teclas +/-
	if event.is_action_pressed("zoom_in"):
		target_zoom = clamp(target_zoom - zoom_speed, min_zoom, max_zoom)
	elif event.is_action_pressed("zoom_out"):
		target_zoom = clamp(target_zoom + zoom_speed, min_zoom, max_zoom)

func _apply_tension_effects(delta: float) -> void:
	if tension_shake_intensity > 0:
		var shake = Vector3(
			randf_range(-1, 1) * tension_shake_intensity,
			randf_range(-1, 1) * tension_shake_intensity * 0.5,
			randf_range(-1, 1) * tension_shake_intensity
		)
		offset = base_offset + shake
		tension_shake_intensity = lerp(tension_shake_intensity, 0.0, delta * 3)
	else:
		offset = base_offset

func shake(intensity: float) -> void:
	tension_shake_intensity = intensity

func _on_tension_changed(phase: int) -> void:
	match phase:
		2:
			shake(0.08)
		3:
			shake(0.2)

func _on_horror_event(event_type: String) -> void:
	match event_type:
		"skinwalker_near":
			shake(0.25)
		"skinwalker_reveal":
			shake(0.4)
		"crucifix_used":
			shake(0.15)

func set_zoom(new_zoom: float) -> void:
	target_zoom = clamp(new_zoom, min_zoom, max_zoom)
