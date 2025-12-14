# res://systems/distraction_system.gd
extends Node
class_name DistractionSystem

# ═══════════════════════════════════════════════════════════════
# SISTEMA DE DISTRACCIONES
# Permite a cazador y cazado engañarse mutuamente
# ═══════════════════════════════════════════════════════════════

# --- TIPOS DE DISTRACCIÓN ---
enum DistractionType {
	DECOY_DEER,
	DECOY_RABBIT,
	NOISE_MAKER,
	FALSE_TRAIL,
	HIDE_SCENT,
	MIMIC_VILLAGER,
	MIMIC_ANIMAL,
	LURE_SOUND,
	FALSE_SAFETY,
	FAKE_ESCAPE_ROUTE
}

# --- CONFIGURACIÓN ---
const DISTRACTION_DURATION: float = 8.0
const COOLDOWN_BASE: float = 15.0
const MAX_ACTIVE_DISTRACTIONS: int = 3

# --- ESTADO ---
var active_distractions: Array = []
var player_cooldowns: Dictionary = {}
var rng: RandomNumberGenerator = RandomNumberGenerator.new()

# --- CLASE DISTRACCIÓN ACTIVA ---
class ActiveDistraction:
	var type: int = 0
	var position: Vector3 = Vector3.ZERO
	var created_by: String = ""
	var time_remaining: float = 0.0
	var visual_node: Node3D = null
	var effectiveness: float = 1.0
	var has_been_triggered: bool = false

func _ready() -> void:
	rng.seed = Time.get_ticks_msec()
	EventsBus.distraction_created.connect(_on_distraction_request)

func _process(delta: float) -> void:
	_update_distractions(delta)
	_update_cooldowns(delta)

func _update_distractions(delta: float) -> void:
	var to_remove: Array = []
	
	for distraction in active_distractions:
		distraction.time_remaining -= delta
		
		if distraction.time_remaining <= 0:
			to_remove.append(distraction)
		else:
			_update_distraction_visual(distraction, delta)
	
	for d in to_remove:
		_remove_distraction(d)

func _update_cooldowns(delta: float) -> void:
	var keys_to_remove: Array = []
	
	for key in player_cooldowns.keys():
		player_cooldowns[key] -= delta
		if player_cooldowns[key] <= 0:
			keys_to_remove.append(key)
	
	for key in keys_to_remove:
		player_cooldowns.erase(key)

func _on_distraction_request(position: Vector3, type_str: String, by_whom: String) -> void:
	var dtype = _string_to_type(type_str)
	create_distraction(dtype, position, by_whom)

func create_distraction(type: int, position: Vector3, creator: String) -> bool:
	var cooldown_key = creator + "_" + str(type)
	if player_cooldowns.has(cooldown_key):
		EventsBus.emit_notification("Distracción en enfriamiento", "warning")
		return false
	
	var creator_distractions = active_distractions.filter(func(d): return d.created_by == creator)
	if creator_distractions.size() >= MAX_ACTIVE_DISTRACTIONS:
		EventsBus.emit_notification("Demasiadas distracciones activas", "warning")
		return false
	
	var distraction = ActiveDistraction.new()
	distraction.type = type
	distraction.position = position
	distraction.created_by = creator
	distraction.time_remaining = DISTRACTION_DURATION
	distraction.visual_node = _create_distraction_visual(type, position)
	
	active_distractions.append(distraction)
	player_cooldowns[cooldown_key] = COOLDOWN_BASE
	
	EventsBus.distraction_triggered.emit(position)
	print("[DISTRACTION] Creada: ", DistractionType.keys()[type], " por ", creator)
	
	return true

func _create_distraction_visual(type: int, position: Vector3) -> Node3D:
	var visual = Node3D.new()
	visual.position = position
	
	var mesh_instance = MeshInstance3D.new()
	visual.add_child(mesh_instance)
	
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	match type:
		DistractionType.DECOY_DEER:
			_build_deer_decoy(st)
		DistractionType.DECOY_RABBIT:
			_build_rabbit_decoy(st)
		DistractionType.NOISE_MAKER:
			_build_noise_visual(st)
		DistractionType.MIMIC_VILLAGER:
			_build_villager_decoy(st)
		DistractionType.LURE_SOUND:
			_build_lure_visual(st)
		_:
			_build_generic_decoy(st)
	
	st.generate_normals()
	mesh_instance.mesh = st.commit()
	
	var light = OmniLight3D.new()
	light.light_color = Color(0.5, 0.5, 0.4)
	light.light_energy = 0.3
	light.omni_range = 3.0
	light.position.y = 1.0
	visual.add_child(light)
	
	add_child(visual)
	return visual

func _build_deer_decoy(st: SurfaceTool) -> void:
	var fur = Color(0.45, 0.35, 0.25)
	_add_box(st, Vector3(-0.3, 0.6, -0.6), Vector3(0.6, 0.4, 1.2), fur)
	_add_box(st, Vector3(-0.2, 0, -0.4), Vector3(0.1, 0.6, 0.1), fur.darkened(0.2))
	_add_box(st, Vector3(0.1, 0, -0.4), Vector3(0.1, 0.6, 0.1), fur.darkened(0.2))
	_add_box(st, Vector3(-0.2, 0, 0.35), Vector3(0.1, 0.6, 0.1), fur.darkened(0.2))
	_add_box(st, Vector3(0.1, 0, 0.35), Vector3(0.1, 0.6, 0.1), fur.darkened(0.2))
	_add_box(st, Vector3(-0.12, 0.85, -0.9), Vector3(0.24, 0.25, 0.35), fur.lightened(0.1))

func _build_rabbit_decoy(st: SurfaceTool) -> void:
	var fur = Color(0.5, 0.45, 0.4)
	_add_box(st, Vector3(-0.1, 0.1, -0.15), Vector3(0.2, 0.15, 0.3), fur)
	_add_box(st, Vector3(-0.08, 0.2, -0.22), Vector3(0.16, 0.12, 0.12), fur.lightened(0.1))
	_add_box(st, Vector3(-0.06, 0.3, -0.2), Vector3(0.04, 0.15, 0.03), fur)
	_add_box(st, Vector3(0.02, 0.3, -0.2), Vector3(0.04, 0.15, 0.03), fur)

func _build_noise_visual(st: SurfaceTool) -> void:
	var metal = Color(0.4, 0.4, 0.45)
	_add_box(st, Vector3(-0.05, 0, -0.05), Vector3(0.1, 0.15, 0.1), metal)

func _build_villager_decoy(st: SurfaceTool) -> void:
	var skin = Color(0.9, 0.75, 0.6)
	var clothes = Color(0.35, 0.25, 0.2)
	_add_box(st, Vector3(-0.25, 0, -0.1), Vector3(0.5, 0.7, 0.25), clothes)
	_add_box(st, Vector3(-0.3, 0.7, -0.15), Vector3(0.6, 0.8, 0.35), clothes)
	_add_box(st, Vector3(-0.2, 1.5, -0.1), Vector3(0.4, 0.4, 0.3), skin)

func _build_lure_visual(st: SurfaceTool) -> void:
	var color = Color(0.6, 0.5, 0.3, 0.5)
	_add_box(st, Vector3(-0.3, 0.5, -0.3), Vector3(0.6, 0.1, 0.6), color)

func _build_generic_decoy(st: SurfaceTool) -> void:
	var color = Color(0.5, 0.4, 0.3)
	_add_box(st, Vector3(-0.2, 0, -0.2), Vector3(0.4, 0.5, 0.4), color)

func _add_box(st: SurfaceTool, pos: Vector3, size: Vector3, color: Color) -> void:
	var corners = [
		pos, pos + Vector3(size.x, 0, 0), pos + Vector3(size.x, 0, size.z), pos + Vector3(0, 0, size.z),
		pos + Vector3(0, size.y, 0), pos + Vector3(size.x, size.y, 0),
		pos + Vector3(size.x, size.y, size.z), pos + Vector3(0, size.y, size.z)
	]
	var faces = [[0,1,5,4], [1,2,6,5], [2,3,7,6], [3,0,4,7], [4,5,6,7], [3,2,1,0]]
	
	for f in faces:
		st.set_color(color)
		st.add_vertex(corners[f[0]])
		st.add_vertex(corners[f[1]])
		st.add_vertex(corners[f[2]])
		st.add_vertex(corners[f[0]])
		st.add_vertex(corners[f[2]])
		st.add_vertex(corners[f[3]])

func _update_distraction_visual(distraction: ActiveDistraction, _delta: float) -> void:
	if distraction.visual_node and is_instance_valid(distraction.visual_node):
		if distraction.time_remaining < 2.0:
			var alpha = distraction.time_remaining / 2.0
			distraction.visual_node.modulate = Color(1, 1, 1, alpha)

func _remove_distraction(distraction: ActiveDistraction) -> void:
	if distraction.visual_node and is_instance_valid(distraction.visual_node):
		distraction.visual_node.queue_free()
	
	active_distractions.erase(distraction)

func get_nearby_distractions(position: Vector3, radius: float) -> Array:
	var nearby: Array = []
	
	for distraction in active_distractions:
		if distraction.position.distance_to(position) <= radius:
			nearby.append(distraction)
	
	return nearby

func is_position_distraction(position: Vector3, threshold: float = 2.0) -> bool:
	for distraction in active_distractions:
		if distraction.position.distance_to(position) <= threshold:
			return true
	return false

func get_available_distractions(game_mode: int) -> Array:
	var available: Array = []
	
	if game_mode == Config.GameMode.HUNTED:
		available = [
			DistractionType.DECOY_DEER,
			DistractionType.DECOY_RABBIT,
			DistractionType.NOISE_MAKER,
			DistractionType.FALSE_TRAIL,
			DistractionType.HIDE_SCENT
		]
	else:
		available = [
			DistractionType.MIMIC_VILLAGER,
			DistractionType.MIMIC_ANIMAL,
			DistractionType.LURE_SOUND,
			DistractionType.FALSE_SAFETY,
			DistractionType.FAKE_ESCAPE_ROUTE
		]
	
	return available

func _string_to_type(type_str: String) -> int:
	match type_str.to_lower():
		"decoy", "decoy_deer": return DistractionType.DECOY_DEER
		"rabbit", "decoy_rabbit": return DistractionType.DECOY_RABBIT
		"noise": return DistractionType.NOISE_MAKER
		"trail": return DistractionType.FALSE_TRAIL
		"scent": return DistractionType.HIDE_SCENT
		"villager": return DistractionType.MIMIC_VILLAGER
		"animal": return DistractionType.MIMIC_ANIMAL
		"lure": return DistractionType.LURE_SOUND
		"safety": return DistractionType.FALSE_SAFETY
		"escape": return DistractionType.FAKE_ESCAPE_ROUTE
		_: return DistractionType.NOISE_MAKER
