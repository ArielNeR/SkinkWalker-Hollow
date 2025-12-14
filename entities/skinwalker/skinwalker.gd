# res://entities/skinwalker/skinwalker.gd
extends CharacterBody3D
class_name Skinwalker

# ═══════════════════════════════════════════════════════════════
# EL CAMBIAPIELES - IA MEJORADA
# Fase 1: Se camufla como aldeano/animal
# Fase 2+: Comienza a perseguir
# ═══════════════════════════════════════════════════════════════

enum State {
	DORMANT,
	STALKING_DISGUISED,  # NUEVO: Acechar mientras está disfrazado
	STALKING,
	HUNTING,
	DISGUISED,
	TRANSFORMING,
	ATTACKING,
	CONFUSED,
	FLEEING_CRUCIFIX
}

var base_speed: float = 2.5
var hunt_speed: float = 4.0
var desperate_speed: float = 5.5
var disguised_speed: float = 1.8
var movement_speed: float = 2.5

var detection_range: float = 20.0
var attack_range: float = 1.8
var vision_angle: float = 140.0

var is_alive: bool = true
var current_state: int = State.DORMANT
var current_disguise: String = ""
var is_disguised: bool = false
var target: Node = null
var last_known_target_pos: Vector3 = Vector3.ZERO

var state_timer: float = 0.0
var transform_cooldown: float = 0.0
var attack_cooldown: float = 0.0
var crucifix_flee_timer: float = 0.0
var disguise_timer: float = 0.0

var animation_time: float = 0.0
var body_parts: Dictionary = {}
var mesh_container: Node3D = null
var disguise_container: Node3D = null
var eyes_glow: OmniLight3D = null
var collision_shape: CollisionShape3D = null

var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var current_tension_phase: int = 0

signal state_changed(new_state: int)

func _ready() -> void:
	movement_speed = base_speed
	rng.seed = Time.get_ticks_msec()
	
	_setup_collision()
	_generate_true_form()
	_setup_eyes()
	_connect_events()
	
	# Comenzar dormido
	current_state = State.DORMANT
	
	EventsBus.skinwalker_spawned.emit()
	print("[SKINWALKER] Spawneado - Estado: DORMANT")

func _setup_collision() -> void:
	collision_shape = CollisionShape3D.new()
	var shape = CapsuleShape3D.new()
	shape.radius = 0.4
	shape.height = 2.0
	collision_shape.shape = shape
	collision_shape.position.y = 1.0
	add_child(collision_shape)

func _generate_true_form() -> void:
	mesh_container = Node3D.new()
	mesh_container.name = "TrueForm"
	add_child(mesh_container)
	
	var flesh = Color(0.25, 0.2, 0.18)
	var dark = Color(0.1, 0.08, 0.06)
	
	# Torso
	var torso = _create_part(Vector3(-0.12, 0.7, -0.07), Vector3(0.24, 0.7, 0.14), flesh)
	mesh_container.add_child(torso)
	
	# Cabeza
	mesh_container.add_child(_create_part(Vector3(-0.1, 1.4, -0.08), Vector3(0.2, 0.3, 0.16), dark))
	
	# Cuernos
	mesh_container.add_child(_create_part(Vector3(-0.08, 1.65, 0), Vector3(0.04, 0.18, 0.04), dark))
	mesh_container.add_child(_create_part(Vector3(0.04, 1.65, 0), Vector3(0.04, 0.18, 0.04), dark))
	
	# Piernas
	var ll_pivot = Node3D.new()
	ll_pivot.position = Vector3(-0.08, 0.7, 0)
	mesh_container.add_child(ll_pivot)
	ll_pivot.add_child(_create_part(Vector3(-0.04, -0.7, -0.04), Vector3(0.08, 0.7, 0.08), flesh.darkened(0.1)))
	body_parts["left_leg"] = ll_pivot
	
	var rl_pivot = Node3D.new()
	rl_pivot.position = Vector3(0.08, 0.7, 0)
	mesh_container.add_child(rl_pivot)
	rl_pivot.add_child(_create_part(Vector3(-0.04, -0.7, -0.04), Vector3(0.08, 0.7, 0.08), flesh.darkened(0.1)))
	body_parts["right_leg"] = rl_pivot
	
	# Brazos
	var la_pivot = Node3D.new()
	la_pivot.position = Vector3(-0.18, 1.3, 0)
	mesh_container.add_child(la_pivot)
	la_pivot.add_child(_create_part(Vector3(-0.035, -0.6, -0.035), Vector3(0.07, 0.6, 0.07), flesh))
	body_parts["left_arm"] = la_pivot
	
	var ra_pivot = Node3D.new()
	ra_pivot.position = Vector3(0.18, 1.3, 0)
	mesh_container.add_child(ra_pivot)
	ra_pivot.add_child(_create_part(Vector3(-0.035, -0.6, -0.035), Vector3(0.07, 0.6, 0.07), flesh))
	body_parts["right_arm"] = ra_pivot

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
		var c = color.lightened(0.08) if i == 4 else color.darkened(i * 0.04)
		st.set_color(c)
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

func _setup_eyes() -> void:
	eyes_glow = OmniLight3D.new()
	eyes_glow.light_color = Color(1.0, 0.25, 0.1)
	eyes_glow.light_energy = 0.8
	eyes_glow.omni_range = 2.5
	eyes_glow.position = Vector3(0, 1.55, 0.08)
	add_child(eyes_glow)
	eyes_glow.visible = false

func _connect_events() -> void:
	EventsBus.tension_phase_changed.connect(_on_tension_phase_changed)
	EventsBus.distraction_created.connect(_on_distraction_created)
	EventsBus.player_spawned.connect(_on_player_spawned)
	EventsBus.horror_event_triggered.connect(_on_horror_event)

func _physics_process(delta: float) -> void:
	if not is_alive:
		return
	
	_update_timers(delta)
	_execute_state(delta)
	_update_animation(delta)
	_update_visuals()

func _update_timers(delta: float) -> void:
	state_timer -= delta
	transform_cooldown -= delta
	attack_cooldown -= delta
	crucifix_flee_timer -= delta
	disguise_timer -= delta

func _execute_state(delta: float) -> void:
	match current_state:
		State.DORMANT:
			pass  # No hace nada
		State.STALKING_DISGUISED:
			_state_stalking_disguised(delta)
		State.STALKING:
			_state_stalking(delta)
		State.HUNTING:
			_state_hunting(delta)
		State.TRANSFORMING:
			_state_transforming()
		State.ATTACKING:
			_state_attacking()
		State.CONFUSED:
			_state_confused(delta)
		State.FLEEING_CRUCIFIX:
			_state_fleeing_crucifix(delta)

func _change_state(new_state: int) -> void:
	var old = current_state
	current_state = new_state
	print("[SKINWALKER] ", State.keys()[old], " -> ", State.keys()[new_state])
	state_changed.emit(new_state)
	
	match new_state:
		State.STALKING_DISGUISED:
			# Disfrazarse al comenzar a acechar
			_set_disguise("villager" if rng.randf() > 0.3 else "deer")
			movement_speed = disguised_speed
		State.HUNTING:
			_reveal_true_form()
			movement_speed = hunt_speed
			EventsBus.skinwalker_detected_player.emit()
		State.FLEEING_CRUCIFIX:
			crucifix_flee_timer = 4.0
			eyes_glow.light_energy = 0.2
		State.CONFUSED:
			state_timer = rng.randf_range(3.0, 5.0)

func _state_stalking_disguised(delta: float) -> void:
	# ═══════════════════════════════════════════════════════════
	# FASE 1: Acechar disfrazado, acercarse lentamente
	# ═══════════════════════════════════════════════════════════
	if target == null or not is_instance_valid(target):
		_find_target()
		return
	
	var dist = global_position.distance_to(target.global_position)
	
	# Cambiar disfraz periódicamente
	if disguise_timer <= 0:
		var options = ["villager", "deer"]
		_set_disguise(options[rng.randi() % options.size()])
		disguise_timer = rng.randf_range(15.0, 30.0)
	
	# Acercarse lentamente mientras está disfrazado
	if dist > 8.0:
		_move_towards(target.global_position, delta, disguised_speed)
	else:
		# Merodear cerca pero no demasiado
		if rng.randf() < 0.02:
			var offset = Vector3(rng.randf_range(-5, 5), 0, rng.randf_range(-5, 5))
			_move_towards(target.global_position + offset, delta, disguised_speed * 0.5)

func _state_stalking(delta: float) -> void:
	if target == null or not is_instance_valid(target):
		_find_target()
		return
	
	var dist = global_position.distance_to(target.global_position)
	
	if dist < detection_range and _can_see_target():
		_change_state(State.HUNTING)
	elif dist > detection_range * 1.5:
		_move_towards(target.global_position, delta, movement_speed * 0.6)

func _state_hunting(delta: float) -> void:
	if target == null or not is_instance_valid(target):
		_change_state(State.STALKING)
		return
	
	var dist = global_position.distance_to(target.global_position)
	
	if dist <= attack_range:
		_change_state(State.ATTACKING)
	elif _can_see_target():
		last_known_target_pos = target.global_position
		_move_towards(target.global_position, delta, movement_speed)
		
		if dist < 8.0:
			EventsBus.emit_horror_event("skinwalker_near")
	else:
		if global_position.distance_to(last_known_target_pos) > 2.0:
			_move_towards(last_known_target_pos, delta, movement_speed * 0.7)
		else:
			EventsBus.skinwalker_lost_player.emit()
			_change_state(State.STALKING)

func _state_transforming() -> void:
	if state_timer <= 0:
		if is_disguised:
			_change_state(State.STALKING_DISGUISED)
		else:
			_change_state(State.HUNTING)

func _state_attacking() -> void:
	if attack_cooldown <= 0 and target and is_instance_valid(target):
		var dist = global_position.distance_to(target.global_position)
		if dist <= attack_range:
			_perform_attack()
		else:
			_change_state(State.HUNTING)

func _state_confused(delta: float) -> void:
	if state_timer <= 0:
		_change_state(State.STALKING)
	else:
		_move_towards(last_known_target_pos, delta, movement_speed * 0.4)

func _state_fleeing_crucifix(delta: float) -> void:
	if crucifix_flee_timer <= 0:
		_change_state(State.STALKING)
		return
	
	if target and is_instance_valid(target):
		var away = (global_position - target.global_position).normalized()
		_move_towards(global_position + away * 20, delta, movement_speed * 1.5)

func _find_target() -> void:
	var players = get_tree().get_nodes_in_group("player")
	for p in players:
		if not p.is_in_group("skinwalker"):
			target = p
			return

func _can_see_target() -> bool:
	if target == null or not is_instance_valid(target):
		return false
	
	var dist = global_position.distance_to(target.global_position)
	if dist > detection_range:
		return false
	
	var to_target = (target.global_position - global_position).normalized()
	var forward = -transform.basis.z
	var angle = rad_to_deg(acos(clamp(forward.dot(to_target), -1.0, 1.0)))
	
	return angle <= vision_angle / 2

func _move_towards(target_pos: Vector3, delta: float, speed: float) -> void:
	var dir = (target_pos - global_position).normalized()
	dir.y = 0
	
	velocity = dir * speed
	move_and_slide()
	
	if velocity.length() > 0.1:
		rotation.y = lerp_angle(rotation.y, atan2(dir.x, dir.z), 6 * delta)

func _perform_attack() -> void:
	if target and is_instance_valid(target) and target.has_method("take_damage"):
		target.take_damage(100)
		EventsBus.skinwalker_killed_target.emit(target)
	
	attack_cooldown = 2.0
	_change_state(State.STALKING)

func _set_disguise(disguise_type: String) -> void:
	current_disguise = disguise_type
	is_disguised = true
	
	mesh_container.visible = false
	eyes_glow.visible = false
	
	if disguise_container:
		disguise_container.queue_free()
	
	disguise_container = Node3D.new()
	disguise_container.name = "Disguise"
	add_child(disguise_container)
	
	match disguise_type:
		"villager":
			_create_villager_disguise()
		"deer":
			_create_deer_disguise()
	
	print("[SKINWALKER] Disfrazado como: ", disguise_type)

func _create_villager_disguise() -> void:
	var skin = Color(0.85, 0.7, 0.55)
	var clothes = Color(0.3, 0.25, 0.2)
	
	disguise_container.add_child(_create_part(Vector3(-0.12, 0.45, -0.06), Vector3(0.24, 0.45, 0.12), clothes))
	disguise_container.add_child(_create_part(Vector3(-0.1, 0.9, -0.05), Vector3(0.2, 0.22, 0.1), skin))
	disguise_container.add_child(_create_part(Vector3(-0.12, 1.1, -0.07), Vector3(0.24, 0.06, 0.14), Color(0.2, 0.15, 0.1)))
	disguise_container.add_child(_create_part(Vector3(-0.1, 0, -0.04), Vector3(0.08, 0.45, 0.08), clothes.darkened(0.15)))
	disguise_container.add_child(_create_part(Vector3(0.02, 0, -0.04), Vector3(0.08, 0.45, 0.08), clothes.darkened(0.15)))

func _create_deer_disguise() -> void:
	var fur = Color(0.45, 0.35, 0.25)
	
	disguise_container.add_child(_create_part(Vector3(-0.2, 0.5, -0.3), Vector3(0.4, 0.35, 0.9), fur))
	disguise_container.add_child(_create_part(Vector3(-0.1, 0.7, 0.5), Vector3(0.2, 0.2, 0.3), fur.lightened(0.1)))
	disguise_container.add_child(_create_part(Vector3(-0.18, 0, 0.35), Vector3(0.08, 0.5, 0.08), fur.darkened(0.15)))
	disguise_container.add_child(_create_part(Vector3(0.1, 0, 0.35), Vector3(0.08, 0.5, 0.08), fur.darkened(0.15)))
	disguise_container.add_child(_create_part(Vector3(-0.18, 0, -0.2), Vector3(0.08, 0.5, 0.08), fur.darkened(0.15)))
	disguise_container.add_child(_create_part(Vector3(0.1, 0, -0.2), Vector3(0.08, 0.5, 0.08), fur.darkened(0.15)))

func _reveal_true_form() -> void:
	current_disguise = ""
	is_disguised = false
	
	if disguise_container:
		disguise_container.queue_free()
		disguise_container = null
	
	mesh_container.visible = true
	eyes_glow.visible = true
	
	EventsBus.emit_horror_event("skinwalker_reveal")

func _update_animation(delta: float) -> void:
	if is_disguised:
		return
	
	var speed = velocity.length()
	if speed > 0.1:
		animation_time += delta * 8.0
		var swing = sin(animation_time) * 0.5
		
		if body_parts.has("left_leg"):
			body_parts["left_leg"].rotation.x = swing
		if body_parts.has("right_leg"):
			body_parts["right_leg"].rotation.x = -swing
		if body_parts.has("left_arm"):
			body_parts["left_arm"].rotation.x = -swing * 0.7
		if body_parts.has("right_arm"):
			body_parts["right_arm"].rotation.x = swing * 0.7
	else:
		animation_time = 0.0
		for key in body_parts:
			body_parts[key].rotation.x = lerp(body_parts[key].rotation.x, 0.0, delta * 6)

func _update_visuals() -> void:
	if is_disguised:
		eyes_glow.visible = false
	else:
		eyes_glow.visible = true
		match current_state:
			State.HUNTING:
				eyes_glow.light_energy = 1.2 + sin(Time.get_ticks_msec() / 150.0) * 0.3
			State.ATTACKING:
				eyes_glow.light_energy = 2.0
			_:
				eyes_glow.light_energy = 0.6

func _on_tension_phase_changed(phase: int) -> void:
	current_tension_phase = phase
	
	match phase:
		1:  # "Algo no está bien" - Comenzar a acechar disfrazado
			if current_state == State.DORMANT:
				_change_state(State.STALKING_DISGUISED)
		2:  # "Te están cazando" - Comenzar persecución
			movement_speed = hunt_speed
			detection_range = 25.0
			if current_state in [State.DORMANT, State.STALKING_DISGUISED]:
				_change_state(State.HUNTING)
		3:  # Desesperación
			movement_speed = desperate_speed
			detection_range = 35.0
			_reveal_true_form()
			_change_state(State.HUNTING)

func _on_distraction_created(pos: Vector3, _type: String, by_whom: String) -> void:
	if by_whom == "player" and current_state in [State.HUNTING, State.STALKING]:
		var dist = global_position.distance_to(pos)
		if dist < detection_range:
			last_known_target_pos = pos
			_change_state(State.CONFUSED)

func _on_player_spawned(player: Node) -> void:
	if not player.is_in_group("skinwalker"):
		target = player

func _on_horror_event(event_type: String) -> void:
	if event_type == "crucifix_used":
		if target and is_instance_valid(target):
			var dist = global_position.distance_to(target.global_position)
			if dist < 8.0:
				_change_state(State.FLEEING_CRUCIFIX)
