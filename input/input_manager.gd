# res://input/input_manager.gd
extends Node

# ═══════════════════════════════════════════════════════════════
# GESTOR DE ENTRADA MULTIPLATAFORMA - AUTOLOAD
# Abstrae la entrada para PC y Android
# ═══════════════════════════════════════════════════════════════

# --- SEÑALES ---
signal movement_input(direction: Vector2)
signal action_pressed(action_name: String)
signal action_released(action_name: String)

# --- ESTADO ---
var current_movement: Vector2 = Vector2.ZERO
var is_touch_enabled: bool = false
var virtual_joystick_active: bool = false

# --- VECTORES ISOMÉTRICOS ---
var iso_forward: Vector3 = Vector3(-1, 0, -1).normalized()
var iso_right: Vector3 = Vector3(1, 0, -1).normalized()

# --- MAPEO DE ACCIONES ---
const ACTIONS: Dictionary = {
	"move_up": "move_up",
	"move_down": "move_down", 
	"move_left": "move_left",
	"move_right": "move_right",
	"interact": "interact",
	"run": "run",
	"use_distraction": "use_distraction",
	"pause": "pause",
	"zoom_in": "zoom_in",
	"zoom_out": "zoom_out"
}

func _ready() -> void:
	print("[INPUT_MANAGER] Autoload inicializado")
	_detect_input_mode()

func _detect_input_mode() -> void:
	is_touch_enabled = Config.is_mobile
	if is_touch_enabled:
		_setup_touch_controls()
	print("[INPUT] Modo de entrada: ", "TÁCTIL" if is_touch_enabled else "TECLADO/MOUSE")

func _process(_delta: float) -> void:
	if is_touch_enabled:
		_process_touch_input()
	else:
		_process_keyboard_input()

func _process_keyboard_input() -> void:
	var input_vector = Vector2.ZERO
	
	input_vector.x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	input_vector.y = Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
	
	if input_vector != current_movement:
		current_movement = input_vector.normalized() if input_vector.length() > 0 else Vector2.ZERO
		movement_input.emit(current_movement)

func _process_touch_input() -> void:
	# Lógica del joystick virtual para móviles
	pass

func _input(event: InputEvent) -> void:
	for action_key in ACTIONS:
		var action_name = ACTIONS[action_key]
		if event.is_action_pressed(action_name):
			action_pressed.emit(action_name)
		elif event.is_action_released(action_name):
			action_released.emit(action_name)

# ═══════════════════════════════════════════════════════════════
# CONTROLES TÁCTILES (ANDROID)
# ═══════════════════════════════════════════════════════════════

func _setup_touch_controls() -> void:
	print("[INPUT] Configurando controles táctiles...")

func get_movement_direction() -> Vector2:
	return current_movement

func is_action_held(action_name: String) -> bool:
	return Input.is_action_pressed(action_name)

# ═══════════════════════════════════════════════════════════════
# CONVERSIÓN ISOMÉTRICA CORREGIDA
# ═══════════════════════════════════════════════════════════════

func get_isometric_movement() -> Vector3:
	if current_movement.length() < 0.1:
		return Vector3.ZERO
	
	# Convertir input 2D a movimiento isométrico 3D
	# current_movement.x: +1 = derecha, -1 = izquierda  
	# current_movement.y: +1 = abajo, -1 = arriba
	
	var iso_direction = iso_right * current_movement.x + iso_forward * (-current_movement.y)
	
	return iso_direction.normalized()

func get_raw_input() -> Vector2:
	return current_movement
