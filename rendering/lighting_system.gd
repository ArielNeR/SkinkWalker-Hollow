# res://rendering/lighting_system.gd
extends Node3D
class_name LightingSystem

# ═══════════════════════════════════════════════════════════════
# SISTEMA DE ILUMINACIÓN NOCTURNA
# AJUSTADO PARA SER MENOS OSCURO (NOCHE PARCIAL)
# ═══════════════════════════════════════════════════════════════

var world_environment: WorldEnvironment = null
var directional_light: DirectionalLight3D = null
var ambient_lights: Array = []

# --- COLORES AJUSTADOS PARA NOCHE PARCIAL ---
const NIGHT_AMBIENT_COLOR: Color = Color(0.08, 0.1, 0.15)  # Más claro
const MOON_COLOR: Color = Color(0.4, 0.45, 0.55)           # Luna más brillante
const LANTERN_COLOR: Color = Color(1.0, 0.8, 0.5)
const FOG_DENSITY: float = 0.008                            # Menos niebla

var current_tension_phase: int = 0
var flicker_timer: float = 0.0

func _ready() -> void:
	_setup_environment()
	_setup_moonlight()
	
	EventsBus.tension_phase_changed.connect(_on_tension_changed)
	EventsBus.world_generated.connect(_on_world_generated)

func _setup_environment() -> void:
	world_environment = WorldEnvironment.new()
	var env = Environment.new()
	
	# Cielo nocturno (azul muy oscuro, no negro)
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.03, 0.04, 0.08)
	
	# Luz ambiental más visible
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = NIGHT_AMBIENT_COLOR
	env.ambient_light_energy = 0.35  # Más luz ambiental
	
	# Niebla sutil
	env.fog_enabled = true
	env.fog_light_color = Color(0.1, 0.12, 0.18)
	env.fog_density = FOG_DENSITY
	
	# Tonemap
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = 1.0
	
	# Glow para luces
	env.glow_enabled = true
	env.glow_intensity = 0.4
	env.glow_bloom = 0.15
	
	# Ajustes de color (ligeramente desaturado)
	env.adjustment_enabled = true
	env.adjustment_saturation = 0.8
	env.adjustment_contrast = 1.05
	
	world_environment.environment = env
	add_child(world_environment)

func _setup_moonlight() -> void:
	directional_light = DirectionalLight3D.new()
	directional_light.light_color = MOON_COLOR
	directional_light.light_energy = 0.4  # Luna más brillante
	directional_light.rotation_degrees = Vector3(-40, -30, 0)
	
	directional_light.shadow_enabled = true
	directional_light.shadow_opacity = 0.5
	
	add_child(directional_light)

func _on_world_generated() -> void:
	await get_tree().process_frame
	_spawn_lantern_lights()

func _spawn_lantern_lights() -> void:
	var wd = _find_world_data()
	if wd == null:
		return
	
	var bounds = wd.get_world_bounds()
	for x in range(bounds.max.x):
		for y in range(bounds.max.y):
			for z in range(bounds.max.z):
				if wd.get_block(x, y, z) == Config.BlockType.LANTERN:
					_create_lantern_light(Vector3(x, y, z))

func _find_world_data():
	if GameManager and GameManager.world_data:
		return GameManager.world_data
	return null

func _create_lantern_light(block_pos: Vector3) -> OmniLight3D:
	var block_size_world = Config.BLOCK_SIZE / 32.0
	var world_pos = block_pos * block_size_world
	
	var light = OmniLight3D.new()
	light.light_color = LANTERN_COLOR
	light.light_energy = 1.5
	light.omni_range = Config.LIGHT_RADIUS_LANTERN * 2.5
	light.omni_attenuation = 1.2
	light.position = world_pos + Vector3(0.5, 0.5, 0.5) * block_size_world
	
	light.shadow_enabled = true
	light.shadow_opacity = 0.7
	
	add_child(light)
	ambient_lights.append(light)
	return light

func _process(delta: float) -> void:
	_update_flicker(delta)
	_update_tension_effects()

func _update_flicker(delta: float) -> void:
	flicker_timer += delta
	for light in ambient_lights:
		if light and is_instance_valid(light):
			var flicker = sin(flicker_timer * 6 + light.position.x) * 0.15
			light.light_energy = 1.5 + flicker

func _update_tension_effects() -> void:
	if world_environment == null or world_environment.environment == null:
		return
	
	var env = world_environment.environment
	
	# La iluminación se oscurece con la tensión
	match current_tension_phase:
		0:
			env.fog_density = FOG_DENSITY
			env.ambient_light_energy = 0.35
			directional_light.light_energy = 0.4
		1:
			env.fog_density = FOG_DENSITY * 1.2
			env.ambient_light_energy = 0.3
			directional_light.light_energy = 0.35
		2:
			env.fog_density = FOG_DENSITY * 1.5
			env.ambient_light_energy = 0.25
			directional_light.light_energy = 0.25
		3:
			env.fog_density = FOG_DENSITY * 2.0
			env.ambient_light_energy = 0.15
			directional_light.light_energy = 0.15

func _on_tension_changed(phase: int) -> void:
	current_tension_phase = phase
