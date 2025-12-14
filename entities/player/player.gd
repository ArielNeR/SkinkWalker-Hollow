# res://entities/player/player.gd
extends CharacterBody3D
class_name Player

# ═══════════════════════════════════════════════════════════════
# JUGADOR - SIN MODELO DUPLICADO
# ═══════════════════════════════════════════════════════════════

@export var walk_speed: float = 3.0
@export var run_speed: float = 5.5
@export var acceleration: float = 8.0
@export var deceleration: float = 10.0
@export var rotation_speed: float = 10.0

@export var stamina_max: float = 100.0
@export var stamina_drain_rate: float = 20.0
@export var stamina_regen_rate: float = 15.0

var max_health: float = 100.0
var current_health: float = 100.0
var current_stamina: float = 100.0
var is_alive: bool = true
var is_running: bool = false
var game_mode: int = 0

var current_velocity: Vector3 = Vector3.ZERO
var input_direction: Vector3 = Vector3.ZERO
var iso_forward: Vector3 = Vector3(-1, 0, -1).normalized()
var iso_right: Vector3 = Vector3(1, 0, -1).normalized()

var animation_time: float = 0.0
var body_parts: Dictionary = {}
var mesh_container: Node3D = null  # SOLO UN CONTENEDOR

var has_crucifix: bool = true
var crucifix_uses: int = 3
var crucifix_cooldown: float = 0.0

var collision_shape: CollisionShape3D = null
var light_source: OmniLight3D = null

signal health_changed(new_health: float, max_val: float)
signal stamina_changed(current: float, max_val: float)
signal crucifix_used(uses_remaining: int)
signal entity_died()

func _ready() -> void:
	current_health = max_health
	current_stamina = stamina_max
	
	_setup_collision()
	_setup_light()
	_generate_body()  # SOLO SE LLAMA UNA VEZ
	
	add_to_group("player")
	EventsBus.player_spawned.emit(self)

func _setup_collision() -> void:
	collision_shape = CollisionShape3D.new()
	var shape = CapsuleShape3D.new()
	shape.radius = 0.3
	shape.height = 1.6
	collision_shape.shape = shape
	collision_shape.position.y = 0.8
	add_child(collision_shape)

func _setup_light() -> void:
	light_source = OmniLight3D.new()
	light_source.light_color = Color(1.0, 0.9, 0.7)
	light_source.light_energy = 0.6
	light_source.omni_range = 4.0
	light_source.position.y = 1.5
	add_child(light_source)

func _generate_body() -> void:
	# ═══════════════════════════════════════════════════════════
	# SOLO UN MESH_CONTAINER - NO DUPLICAR
	# ═══════════════════════════════════════════════════════════
	if mesh_container != null:
		mesh_container.queue_free()
		body_parts.clear()
	
	mesh_container = Node3D.new()
	mesh_container.name = "PlayerBody"
	add_child(mesh_container)
	
	var body_color: Color
	var pants_color: Color
	var skin_color = Color(0.85, 0.7, 0.55)
	var hat_color = Color(0.2, 0.12, 0.08)
	
	if game_mode == Config.GameMode.HUNTED:
		body_color = Color(0.25, 0.35, 0.2)
		pants_color = Color(0.3, 0.25, 0.15)
	else:
		body_color = Color(0.15, 0.1, 0.1)
		pants_color = Color(0.1, 0.08, 0.08)
		skin_color = Color(0.6, 0.5, 0.45)
	
	# TORSO
	var torso = _create_part(Vector3(-0.15, 0.5, -0.075), Vector3(0.3, 0.45, 0.15), body_color)
	mesh_container.add_child(torso)
	
	# CABEZA
	var head = _create_part(Vector3(-0.12, 0.95, -0.06), Vector3(0.24, 0.24, 0.12), skin_color)
	mesh_container.add_child(head)
	
	# SOMBRERO
	if game_mode == Config.GameMode.HUNTED:
		mesh_container.add_child(_create_part(Vector3(-0.18, 1.17, -0.1), Vector3(0.36, 0.03, 0.2), hat_color))
		mesh_container.add_child(_create_part(Vector3(-0.1, 1.19, -0.05), Vector3(0.2, 0.1, 0.1), hat_color))
	
	# PIERNAS con pivotes
	var ll_pivot = Node3D.new()
	ll_pivot.position = Vector3(-0.08, 0.5, 0)
	mesh_container.add_child(ll_pivot)
	ll_pivot.add_child(_create_part(Vector3(-0.045, -0.5, -0.045), Vector3(0.09, 0.5, 0.09), pants_color))
	body_parts["left_leg"] = ll_pivot
	
	var rl_pivot = Node3D.new()
	rl_pivot.position = Vector3(0.08, 0.5, 0)
	mesh_container.add_child(rl_pivot)
	rl_pivot.add_child(_create_part(Vector3(-0.045, -0.5, -0.045), Vector3(0.09, 0.5, 0.09), pants_color))
	body_parts["right_leg"] = rl_pivot
	
	# BRAZOS con pivotes
	var la_pivot = Node3D.new()
	la_pivot.position = Vector3(-0.2, 0.9, 0)
	mesh_container.add_child(la_pivot)
	la_pivot.add_child(_create_part(Vector3(-0.04, -0.4, -0.04), Vector3(0.08, 0.4, 0.08), skin_color))
	body_parts["left_arm"] = la_pivot
	
	var ra_pivot = Node3D.new()
	ra_pivot.position = Vector3(0.2, 0.9, 0)
	mesh_container.add_child(ra_pivot)
	ra_pivot.add_child(_create_part(Vector3(-0.04, -0.4, -0.04), Vector3(0.08, 0.4, 0.08), skin_color))
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
	var shades = [0.0, -0.08, -0.12, -0.08, 0.08, -0.18]
	
	for i in range(faces.size()):
		var c = color.lightened(shades[i]) if shades[i] > 0 else color.darkened(-shades[i])
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

func _physics_process(delta: float) -> void:
	if not is_alive:
		return
	
	_handle_input()
	_handle_movement(delta)
	_handle_stamina(delta)
	_update_animation(delta)
	_update_crucifix_cooldown(delta)

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
	var speed = run_speed if is_running and current_stamina > 0 else walk_speed
	var target = input_direction * speed
	
	if input_direction.length() > 0.1:
		current_velocity = current_velocity.lerp(target, acceleration * delta)
	else:
		current_velocity = current_velocity.lerp(Vector3.ZERO, deceleration * delta)
		if current_velocity.length() < 0.1:
			current_velocity = Vector3.ZERO
	
	velocity = current_velocity
	move_and_slide()
	
	if current_velocity.length() > 0.1:
		rotation.y = lerp_angle(rotation.y, atan2(current_velocity.x, current_velocity.z), rotation_speed * delta)

func _handle_stamina(delta: float) -> void:
	if is_running and current_velocity.length() > 0.1:
		current_stamina -= stamina_drain_rate * delta
		if current_stamina <= 0:
			current_stamina = 0
			is_running = false
	else:
		current_stamina = min(current_stamina + stamina_regen_rate * delta, stamina_max)
	
	stamina_changed.emit(current_stamina, stamina_max)

func _update_animation(delta: float) -> void:
	var speed = current_velocity.length()
	
	if speed > 0.1:
		var anim_speed = 8.0 if is_running else 5.0
		animation_time += delta * anim_speed
		var swing = sin(animation_time) * (0.6 if is_running else 0.4)
		
		if body_parts.has("left_leg"):
			body_parts["left_leg"].rotation.x = swing
		if body_parts.has("right_leg"):
			body_parts["right_leg"].rotation.x = -swing
		if body_parts.has("left_arm"):
			body_parts["left_arm"].rotation.x = -swing
		if body_parts.has("right_arm"):
			body_parts["right_arm"].rotation.x = swing
	else:
		animation_time = 0.0
		for key in body_parts:
			body_parts[key].rotation.x = lerp(body_parts[key].rotation.x, 0.0, delta * 10)

func _update_crucifix_cooldown(delta: float) -> void:
	if crucifix_cooldown > 0:
		crucifix_cooldown -= delta

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("run"):
		is_running = true
	elif event.is_action_released("run"):
		is_running = false
	elif event.is_action_pressed("use_distraction"):
		_use_crucifix()

func _use_crucifix() -> void:
	if crucifix_cooldown > 0:
		EventsBus.emit_notification("Crucifijo en enfriamiento", "warning")
		return
	
	if crucifix_uses <= 0:
		EventsBus.emit_notification("El crucifijo ya no tiene poder", "danger")
		return
	
	crucifix_uses -= 1
	crucifix_cooldown = 10.0
	
	EventsBus.emit_horror_event("crucifix_used")
	crucifix_used.emit(crucifix_uses)
	
	# Efecto visual
	var flash = OmniLight3D.new()
	flash.light_color = Color(1.0, 0.9, 0.5)
	flash.light_energy = 3.0
	flash.omni_range = 8.0
	flash.position = Vector3(0, 1, 0)
	add_child(flash)
	
	var tween = create_tween()
	tween.tween_property(flash, "light_energy", 0.0, 3.0)
	tween.tween_callback(flash.queue_free)
	
	if crucifix_uses > 0:
		EventsBus.emit_notification("¡El crucifijo lo repele! (" + str(crucifix_uses) + " usos)", "bonus")
	else:
		EventsBus.emit_notification("¡Último uso del crucifijo!", "warning")

func take_damage(amount: float) -> void:
	if not is_alive:
		return
	current_health -= amount
	health_changed.emit(current_health, max_health)
	if current_health <= 0:
		die()

func die() -> void:
	is_alive = false
	entity_died.emit()
	EventsBus.player_died.emit("killed")

func set_game_mode(mode: int) -> void:
	game_mode = mode
	_generate_body()
