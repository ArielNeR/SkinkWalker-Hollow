# res://entities/npcs/prey_npc.gd
extends CharacterBody3D
class_name PreyNPC

# ═══════════════════════════════════════════════════════════════
# PRESA PRINCIPAL - MENSAJE CORRECTO AL ESCAPAR
# ═══════════════════════════════════════════════════════════════

var movement_speed: float = 2.8
var run_speed: float = 4.5
var current_speed: float = 2.8

var is_alive: bool = true
var is_fleeing: bool = false
var has_seen_skinwalker: bool = false

var home_position: Vector3 = Vector3.ZERO
var target_position: Vector3 = Vector3.ZERO
var escape_progress: float = 0.0

var animation_time: float = 0.0
var mesh_container: Node3D = null
var body_parts: Dictionary = {}

var fear_timer: float = 0.0
var search_timer: float = 0.0

signal prey_escaped()
signal prey_died()

func _ready() -> void:
	home_position = global_position
	_generate_body()
	_pick_new_target()
	
	add_to_group("prey")
	print("[PREY] Presa principal spawneada")

func _generate_body() -> void:
	mesh_container = Node3D.new()
	add_child(mesh_container)
	
	var skin = Color(0.88, 0.75, 0.6)
	var clothes = Color(0.7, 0.6, 0.5)
	var accent = Color(0.8, 0.3, 0.2)
	
	# Torso
	mesh_container.add_child(_create_part(Vector3(-0.12, 0.45, -0.06), Vector3(0.24, 0.45, 0.12), clothes))
	
	# Pañuelo rojo distintivo
	mesh_container.add_child(_create_part(Vector3(-0.08, 0.85, -0.04), Vector3(0.16, 0.08, 0.08), accent))
	
	# Cabeza
	mesh_container.add_child(_create_part(Vector3(-0.1, 0.93, -0.05), Vector3(0.2, 0.2, 0.1), skin))
	
	# Sombrero
	mesh_container.add_child(_create_part(Vector3(-0.13, 1.11, -0.08), Vector3(0.26, 0.05, 0.16), Color(0.25, 0.18, 0.12)))
	
	# Piernas con pivotes
	var ll = Node3D.new()
	ll.position = Vector3(-0.06, 0.45, 0)
	mesh_container.add_child(ll)
	ll.add_child(_create_part(Vector3(-0.04, -0.45, -0.04), Vector3(0.08, 0.45, 0.08), clothes.darkened(0.2)))
	body_parts["left_leg"] = ll
	
	var rl = Node3D.new()
	rl.position = Vector3(0.06, 0.45, 0)
	mesh_container.add_child(rl)
	rl.add_child(_create_part(Vector3(-0.04, -0.45, -0.04), Vector3(0.08, 0.45, 0.08), clothes.darkened(0.2)))
	body_parts["right_leg"] = rl
	
	# Brazos con pivotes
	var la = Node3D.new()
	la.position = Vector3(-0.16, 0.85, 0)
	mesh_container.add_child(la)
	la.add_child(_create_part(Vector3(-0.035, -0.35, -0.035), Vector3(0.07, 0.35, 0.07), skin))
	body_parts["left_arm"] = la
	
	var ra = Node3D.new()
	ra.position = Vector3(0.16, 0.85, 0)
	mesh_container.add_child(ra)
	ra.add_child(_create_part(Vector3(-0.035, -0.35, -0.035), Vector3(0.07, 0.35, 0.07), skin))
	body_parts["right_arm"] = ra
	
	# Linterna
	var lantern = OmniLight3D.new()
	lantern.light_color = Color(1.0, 0.85, 0.6)
	lantern.light_energy = 0.6
	lantern.omni_range = 4.0
	lantern.position = Vector3(0.2, 0.6, 0)
	add_child(lantern)

func _create_part(pos: Vector3, size: Vector3, color: Color) -> MeshInstance3D:
	var mi = MeshInstance3D.new()
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	var corners = [
		pos, pos + Vector3(size.x, 0, 0), pos + Vector3(size.x, 0, size.z), pos + Vector3(0, 0, size.z),
		pos + Vector3(0, size.y, 0), pos + Vector3(size.x, size.y, 0),
		pos + Vector3(size.x, size.y, size.z), pos + Vector3(0, size.y, size.z)
	]
	var faces = [[0,1,5,4], [1,2,6,5], [2,3,7,6], [3,0,4,7], [4,5,6,7], [3,2,1,0]]
	
	for i in range(faces.size()):
		st.set_color(color.lightened(0.05) if i == 4 else color.darkened(i * 0.03))
		var f = faces[i]
		st.add_vertex(corners[f[0]])
		st.add_vertex(corners[f[1]])
		st.add_vertex(corners[f[2]])
		st.add_vertex(corners[f[0]])
		st.add_vertex(corners[f[2]])
		st.add_vertex(corners[f[3]])
	
	st.generate_normals()
	mi.mesh = st.commit()
	return mi

func _physics_process(delta: float) -> void:
	if not is_alive:
		return
	
	_update_timers(delta)
	_check_for_threats()
	_move(delta)
	_animate(delta)
	_check_escape()

func _update_timers(delta: float) -> void:
	fear_timer -= delta
	search_timer -= delta
	
	if search_timer <= 0:
		_pick_new_target()
		search_timer = randf_range(5.0, 12.0)

func _check_for_threats() -> void:
	var skinwalkers = get_tree().get_nodes_in_group("skinwalker")
	
	for sw in skinwalkers:
		if is_instance_valid(sw):
			var dist = global_position.distance_to(sw.global_position)
			
			var sw_disguised = false
			if sw.get("is_disguised") != null:
				sw_disguised = sw.is_disguised
			
			if dist < 10.0 and not sw_disguised:
				is_fleeing = true
				has_seen_skinwalker = true
				fear_timer = 5.0
				var away = (global_position - sw.global_position).normalized()
				target_position = global_position + away * 20
				return
			elif dist < 5.0:
				is_fleeing = true
				fear_timer = 3.0
				var away = (global_position - sw.global_position).normalized()
				target_position = global_position + away * 15
				return
	
	if fear_timer <= 0:
		is_fleeing = false

func _pick_new_target() -> void:
	if has_seen_skinwalker or randf() < 0.3:
		var escapes = [
			Vector3(64, 6, 8),
			Vector3(8, 6, 64),
			Vector3(64, 6, 120),
			Vector3(120, 6, 64)
		]
		target_position = escapes[randi() % escapes.size()]
	else:
		target_position = home_position + Vector3(randf_range(-15, 15), 0, randf_range(-15, 15))

func _move(delta: float) -> void:
	current_speed = run_speed if is_fleeing else movement_speed
	
	var dir = (target_position - global_position).normalized()
	dir.y = 0
	
	velocity = dir * current_speed
	move_and_slide()
	
	if global_position.distance_to(target_position) < 2.0 and not is_fleeing:
		velocity = Vector3.ZERO
	
	if velocity.length() > 0.1:
		rotation.y = lerp_angle(rotation.y, atan2(dir.x, dir.z), 8 * delta)

func _animate(delta: float) -> void:
	var speed = velocity.length()
	if speed > 0.1:
		var anim_speed = 10.0 if is_fleeing else 6.0
		animation_time += delta * anim_speed
		var swing = sin(animation_time) * 0.4
		
		for key in ["left_leg", "right_leg"]:
			if body_parts.has(key):
				body_parts[key].rotation.x = swing if key == "left_leg" else -swing
		for key in ["left_arm", "right_arm"]:
			if body_parts.has(key):
				body_parts[key].rotation.x = -swing * 0.6 if key == "left_arm" else swing * 0.6
	else:
		animation_time = 0.0
		for key in body_parts:
			body_parts[key].rotation.x = lerp(body_parts[key].rotation.x, 0.0, delta * 6)

func _check_escape() -> void:
	var pos = global_position
	if pos.x < 10 or pos.x > 118 or pos.z < 10 or pos.z > 118:
		escape_progress += 0.02
		
		if escape_progress >= 1.0:
			_escape()

func _escape() -> void:
	print("[PREY] ¡La presa escapó!")
	prey_escaped.emit()
	
	# ═══════════════════════════════════════════════════════════
	# MENSAJE CORRECTO: DERROTA PARA EL CAZADOR
	# ═══════════════════════════════════════════════════════════
	EventsBus.game_ended.emit(false, "La presa escapó del pueblo. Has fallado en la cacería.")
	
	queue_free()

func take_damage(_amount: float) -> void:
	die()

func die() -> void:
	if not is_alive:
		return
	is_alive = false
	prey_died.emit()
	queue_free()
