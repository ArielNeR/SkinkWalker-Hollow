# res://entities/player/hunter_player.gd
extends CharacterBody3D
class_name HunterPlayer

# ═══════════════════════════════════════════════════════════════
# JUGADOR COMO CAMBIAPIELES - DISFRACES ANIMADOS
# ═══════════════════════════════════════════════════════════════

var base_speed: float = 3.5
var hunt_speed: float = 5.5
var disguised_walk_speed: float = 2.0
var disguised_run_speed: float = 4.0  # PUEDE CORRER DISFRAZADO
var movement_speed: float = 3.5

var is_alive: bool = true
var is_disguised: bool = false
var is_running: bool = false
var current_disguise: String = ""

var transform_cooldown: float = 0.0
var attack_cooldown: float = 0.0
var kills: int = 0
const TRANSFORM_COOLDOWN_TIME: float = 8.0
const ATTACK_RANGE: float = 2.0

var current_velocity: Vector3 = Vector3.ZERO
var input_direction: Vector3 = Vector3.ZERO
var iso_forward: Vector3 = Vector3(-1, 0, -1).normalized()
var iso_right: Vector3 = Vector3(1, 0, -1).normalized()

var animation_time: float = 0.0
var body_parts: Dictionary = {}
var disguise_body_parts: Dictionary = {}  # Partes animables del disfraz
var mesh_container: Node3D = null
var disguise_container: Node3D = null

var collision_shape: CollisionShape3D = null
var eyes_glow: OmniLight3D = null
var detection_area: Area3D = null

signal prey_killed(prey: Node)
signal disguise_changed(disguise_type: String)

func _ready() -> void:
	_setup_collision()
	_setup_detection_area()
	_generate_true_form()
	_setup_eyes()
	
	add_to_group("player")
	add_to_group("skinwalker")
	
	EventsBus.player_spawned.emit(self)
	print("[HUNTER] Modo Cazador iniciado")

func _setup_collision() -> void:
	collision_shape = CollisionShape3D.new()
	var shape = CapsuleShape3D.new()
	shape.radius = 0.4
	shape.height = 2.0
	collision_shape.shape = shape
	collision_shape.position.y = 1.0
	add_child(collision_shape)

func _setup_detection_area() -> void:
	detection_area = Area3D.new()
	var area_shape = CollisionShape3D.new()
	var sphere = SphereShape3D.new()
	sphere.radius = ATTACK_RANGE * 1.5
	area_shape.shape = sphere
	area_shape.position.y = 1.0
	detection_area.add_child(area_shape)
	add_child(detection_area)

func _generate_true_form() -> void:
	if mesh_container:
		mesh_container.queue_free()
		body_parts.clear()
	
	mesh_container = Node3D.new()
	mesh_container.name = "TrueForm"
	add_child(mesh_container)
	
	var flesh = Color(0.22, 0.18, 0.15)
	var dark = Color(0.08, 0.06, 0.05)
	
	# Torso
	mesh_container.add_child(_create_part(Vector3(-0.12, 0.7, -0.07), Vector3(0.24, 0.7, 0.14), flesh))
	
	# Cabeza
	mesh_container.add_child(_create_part(Vector3(-0.1, 1.4, -0.08), Vector3(0.2, 0.3, 0.16), dark))
	
	# Cuernos
	mesh_container.add_child(_create_part(Vector3(-0.08, 1.65, 0), Vector3(0.04, 0.18, 0.04), dark))
	mesh_container.add_child(_create_part(Vector3(0.04, 1.65, 0), Vector3(0.04, 0.18, 0.04), dark))
	
	# Piernas con pivotes
	var ll = Node3D.new()
	ll.position = Vector3(-0.08, 0.7, 0)
	mesh_container.add_child(ll)
	ll.add_child(_create_part(Vector3(-0.04, -0.7, -0.04), Vector3(0.08, 0.7, 0.08), flesh.darkened(0.1)))
	body_parts["left_leg"] = ll
	
	var rl = Node3D.new()
	rl.position = Vector3(0.08, 0.7, 0)
	mesh_container.add_child(rl)
	rl.add_child(_create_part(Vector3(-0.04, -0.7, -0.04), Vector3(0.08, 0.7, 0.08), flesh.darkened(0.1)))
	body_parts["right_leg"] = rl
	
	# Brazos con pivotes
	var la = Node3D.new()
	la.position = Vector3(-0.18, 1.3, 0)
	mesh_container.add_child(la)
	la.add_child(_create_part(Vector3(-0.035, -0.6, -0.035), Vector3(0.07, 0.6, 0.07), flesh))
	body_parts["left_arm"] = la
	
	var ra = Node3D.new()
	ra.position = Vector3(0.18, 1.3, 0)
	mesh_container.add_child(ra)
	ra.add_child(_create_part(Vector3(-0.035, -0.6, -0.035), Vector3(0.07, 0.6, 0.07), flesh))
	body_parts["right_arm"] = ra

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
	eyes_glow.light_energy = 1.0
	eyes_glow.omni_range = 2.5
	eyes_glow.position = Vector3(0, 1.55, 0.08)
	add_child(eyes_glow)

func _physics_process(delta: float) -> void:
	if not is_alive:
		return
	
	_update_cooldowns(delta)
	_handle_input()
	_handle_movement(delta)
	_update_animation(delta)
	_update_eyes()

func _update_cooldowns(delta: float) -> void:
	transform_cooldown -= delta
	attack_cooldown -= delta

func _handle_input() -> void:
	var raw = Vector2(
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
		Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
	)
	
	if raw.length() > 0.1:
		input_direction = iso_right * raw.x + iso_forward * (-raw.y)
		input_direction = input_direction.normalized()
	else:
		input_direction = Vector3.ZERO

func _handle_movement(delta: float) -> void:
	var speed: float
	
	if is_disguised:
		# ═══════════════════════════════════════════════════════════
		# PUEDE CORRER DISFRAZADO
		# ═══════════════════════════════════════════════════════════
		speed = disguised_run_speed if is_running else disguised_walk_speed
	else:
		speed = hunt_speed if is_running else base_speed
	
	var target = input_direction * speed
	
	current_velocity = current_velocity.lerp(target, 8.0 * delta)
	if current_velocity.length() < 0.1:
		current_velocity = Vector3.ZERO
	
	velocity = current_velocity
	move_and_slide()
	
	if velocity.length() > 0.1:
		rotation.y = lerp_angle(rotation.y, atan2(velocity.x, velocity.z), 10 * delta)

func _update_animation(delta: float) -> void:
	var speed = velocity.length()
	
	if speed > 0.1:
		var anim_speed = 10.0 if is_running else 6.0
		animation_time += delta * anim_speed
		var swing = sin(animation_time) * (0.6 if is_running else 0.4)
		
		if is_disguised:
			# ═══════════════════════════════════════════════════════════
			# ANIMAR DISFRAZ
			# ═══════════════════════════════════════════════════════════
			_animate_disguise(swing)
		else:
			# Animar forma verdadera
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
		# Volver a posición neutral
		for key in body_parts:
			body_parts[key].rotation.x = lerp(body_parts[key].rotation.x, 0.0, delta * 6)
		for key in disguise_body_parts:
			disguise_body_parts[key].rotation.x = lerp(disguise_body_parts[key].rotation.x, 0.0, delta * 6)

func _animate_disguise(swing: float) -> void:
	match current_disguise:
		"villager":
			if disguise_body_parts.has("left_leg"):
				disguise_body_parts["left_leg"].rotation.x = swing
			if disguise_body_parts.has("right_leg"):
				disguise_body_parts["right_leg"].rotation.x = -swing
			if disguise_body_parts.has("left_arm"):
				disguise_body_parts["left_arm"].rotation.x = -swing * 0.6
			if disguise_body_parts.has("right_arm"):
				disguise_body_parts["right_arm"].rotation.x = swing * 0.6
		"deer":
			# Patas del venado
			if disguise_body_parts.has("fl"):
				disguise_body_parts["fl"].rotation.x = swing
			if disguise_body_parts.has("fr"):
				disguise_body_parts["fr"].rotation.x = -swing
			if disguise_body_parts.has("bl"):
				disguise_body_parts["bl"].rotation.x = -swing
			if disguise_body_parts.has("br"):
				disguise_body_parts["br"].rotation.x = swing

func _update_eyes() -> void:
	if is_disguised:
		eyes_glow.light_energy = 0.0
	else:
		eyes_glow.light_energy = 0.8 + sin(Time.get_ticks_msec() / 200.0) * 0.3

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("run"):
		is_running = true
	elif event.is_action_released("run"):
		is_running = false
	elif event.is_action_pressed("use_distraction"):
		_cycle_disguise()
	elif event.is_action_pressed("interact"):
		_try_attack()

func _cycle_disguise() -> void:
	if transform_cooldown > 0:
		EventsBus.emit_notification("Transformación en enfriamiento (" + str(int(transform_cooldown)) + "s)", "warning")
		return
	
	var disguises = ["", "villager", "deer"]
	var idx = disguises.find(current_disguise)
	var next = (idx + 1) % disguises.size()
	
	_set_disguise(disguises[next])
	transform_cooldown = TRANSFORM_COOLDOWN_TIME

func _set_disguise(disguise_type: String) -> void:
	current_disguise = disguise_type
	is_disguised = (disguise_type != "")
	
	mesh_container.visible = not is_disguised
	eyes_glow.visible = not is_disguised
	
	if disguise_container:
		disguise_container.queue_free()
		disguise_container = null
	disguise_body_parts.clear()
	
	if is_disguised:
		_create_disguise(disguise_type)
		EventsBus.emit_notification("🎭 Disfrazado como " + disguise_type, "info")
	else:
		EventsBus.emit_notification("👹 Forma verdadera revelada", "danger")
	
	disguise_changed.emit(disguise_type)

func _create_disguise(disguise_type: String) -> void:
	disguise_container = Node3D.new()
	disguise_container.name = "Disguise"
	add_child(disguise_container)
	
	match disguise_type:
		"villager":
			_create_villager_disguise()
		"deer":
			_create_deer_disguise()

func _create_villager_disguise() -> void:
	var skin = Color(0.85, 0.7, 0.55)
	var clothes = Color(0.3, 0.25, 0.2)
	
	# Torso (estático)
	disguise_container.add_child(_create_part(Vector3(-0.12, 0.45, -0.06), Vector3(0.24, 0.45, 0.12), clothes))
	
	# Cabeza (estática)
	disguise_container.add_child(_create_part(Vector3(-0.1, 0.9, -0.05), Vector3(0.2, 0.22, 0.1), skin))
	
	# Sombrero
	disguise_container.add_child(_create_part(Vector3(-0.12, 1.1, -0.07), Vector3(0.24, 0.06, 0.14), Color(0.2, 0.15, 0.1)))
	
	# Piernas CON PIVOTES para animación
	var ll = Node3D.new()
	ll.position = Vector3(-0.06, 0.45, 0)
	disguise_container.add_child(ll)
	ll.add_child(_create_part(Vector3(-0.04, -0.45, -0.04), Vector3(0.08, 0.45, 0.08), clothes.darkened(0.15)))
	disguise_body_parts["left_leg"] = ll
	
	var rl = Node3D.new()
	rl.position = Vector3(0.06, 0.45, 0)
	disguise_container.add_child(rl)
	rl.add_child(_create_part(Vector3(-0.04, -0.45, -0.04), Vector3(0.08, 0.45, 0.08), clothes.darkened(0.15)))
	disguise_body_parts["right_leg"] = rl
	
	# Brazos CON PIVOTES
	var la = Node3D.new()
	la.position = Vector3(-0.16, 0.85, 0)
	disguise_container.add_child(la)
	la.add_child(_create_part(Vector3(-0.03, -0.35, -0.03), Vector3(0.06, 0.35, 0.06), skin))
	disguise_body_parts["left_arm"] = la
	
	var ra = Node3D.new()
	ra.position = Vector3(0.16, 0.85, 0)
	disguise_container.add_child(ra)
	ra.add_child(_create_part(Vector3(-0.03, -0.35, -0.03), Vector3(0.06, 0.35, 0.06), skin))
	disguise_body_parts["right_arm"] = ra

func _create_deer_disguise() -> void:
	var fur = Color(0.45, 0.35, 0.25)
	
	# Cuerpo (estático)
	disguise_container.add_child(_create_part(Vector3(-0.2, 0.5, -0.3), Vector3(0.4, 0.35, 0.9), fur))
	
	# Cabeza (estática, al frente)
	disguise_container.add_child(_create_part(Vector3(-0.1, 0.7, 0.5), Vector3(0.2, 0.2, 0.3), fur.lightened(0.1)))
	
	# Cola
	disguise_container.add_child(_create_part(Vector3(-0.03, 0.7, -0.4), Vector3(0.06, 0.08, 0.12), fur.lightened(0.2)))
	
	# Patas CON PIVOTES para animación
	var positions = [
		["fl", Vector3(-0.15, 0.5, 0.4)],   # Delantera izquierda
		["fr", Vector3(0.08, 0.5, 0.4)],    # Delantera derecha
		["bl", Vector3(-0.15, 0.5, -0.15)], # Trasera izquierda
		["br", Vector3(0.08, 0.5, -0.15)]   # Trasera derecha
	]
	
	for p in positions:
		var pivot = Node3D.new()
		pivot.position = p[1]
		disguise_container.add_child(pivot)
		pivot.add_child(_create_part(Vector3(-0.04, -0.5, -0.04), Vector3(0.08, 0.5, 0.08), fur.darkened(0.15)))
		disguise_body_parts[p[0]] = pivot

func _try_attack() -> void:
	if attack_cooldown > 0:
		return
	
	# Revelar al atacar
	if is_disguised:
		_set_disguise("")
	
	var bodies = detection_area.get_overlapping_bodies()
	for body in bodies:
		if body == self:
			continue
		if body.is_in_group("prey") or body.is_in_group("villager"):
			if global_position.distance_to(body.global_position) <= ATTACK_RANGE:
				_attack_target(body)
				return
	
	EventsBus.emit_notification("No hay presas cerca", "info")

func _attack_target(target: Node) -> void:
	if target.has_method("die"):
		target.die()
	elif target.has_method("take_damage"):
		target.take_damage(100)
	
	kills += 1
	attack_cooldown = 1.5
	
	prey_killed.emit(target)
	EventsBus.emit_notification("🩸 ¡Presa eliminada! (" + str(kills) + " muertes)", "danger")
	
	if target.is_in_group("prey"):
		# Victoria: Cazó a la presa principal
		await get_tree().create_timer(0.5).timeout
		EventsBus.game_ended.emit(true, "¡La presa ha caído! Total de víctimas: " + str(kills))

func take_damage(_amount: float) -> void:
	pass

func die() -> void:
	is_alive = false
	EventsBus.player_died.emit("defeated")
