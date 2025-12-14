# res://entities/base_entity.gd
extends CharacterBody3D
class_name BaseEntity

# ═══════════════════════════════════════════════════════════════
# ENTIDAD BASE
# Clase padre para todas las entidades del juego
# ═══════════════════════════════════════════════════════════════

# --- PROPIEDADES COMUNES ---
@export var entity_name: String = "Entity"
@export var max_health: float = 100.0
@export var movement_speed: float = 100.0

var current_health: float = 100.0
var is_alive: bool = true

# --- COMPONENTES VISUALES ---
var mesh_instance: MeshInstance3D = null
var collision_shape: CollisionShape3D = null

# --- SEÑALES ---
signal health_changed(new_health: float, max_val: float)
signal entity_died()

func _ready() -> void:
	current_health = max_health
	_setup_collision()
	_generate_visual()
	_on_entity_ready()

func _setup_collision() -> void:
	collision_shape = CollisionShape3D.new()
	var shape = CapsuleShape3D.new()
	shape.radius = 0.4
	shape.height = 1.8
	collision_shape.shape = shape
	collision_shape.position.y = 0.9
	add_child(collision_shape)

# Método virtual para que las subclases generen su visual
func _generate_visual() -> void:
	pass

# Método virtual para inicialización adicional
func _on_entity_ready() -> void:
	pass

func take_damage(amount: float) -> void:
	if not is_alive:
		return
	
	current_health -= amount
	health_changed.emit(current_health, max_health)
	
	if current_health <= 0:
		die()

func heal(amount: float) -> void:
	current_health = min(current_health + amount, max_health)
	health_changed.emit(current_health, max_health)

func die() -> void:
	is_alive = false
	entity_died.emit()
	EventsBus.entity_died.emit(self)
