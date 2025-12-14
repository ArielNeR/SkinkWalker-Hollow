# res://entities/npcs/villager_system.gd
extends Node
class_name VillagerSystem

# ═══════════════════════════════════════════════════════════════
# SISTEMA DE ALDEANOS - PUEDEN SER CAZADOS
# ═══════════════════════════════════════════════════════════════

var world_data = null
var generator = null
var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var active_villagers: Array = []

const SKIN_COLORS: Array = [
	Color(0.92, 0.82, 0.72),
	Color(0.82, 0.68, 0.52),
	Color(0.62, 0.48, 0.38),
]

const CLOTHES_COLORS: Array = [
	Color(0.35, 0.28, 0.22),
	Color(0.25, 0.22, 0.28),
	Color(0.4, 0.2, 0.15),
	Color(0.2, 0.25, 0.2),
]

class Villager extends CharacterBody3D:
	var villager_id: int = 0
	var display_name: String = "Aldeano"
	var appearance: Dictionary = {}
	var home_position: Vector3 = Vector3.ZERO
	var current_state: int = 0
	var wander_target: Vector3 = Vector3.ZERO
	var state_timer: float = 0.0
	var movement_speed: float = 1.5
	var is_alive: bool = true
	
	var animation_time: float = 0.0
	var body_parts: Dictionary = {}
	var mesh_container: Node3D = null
	
	func _ready() -> void:
		_generate_body()
		_start_behavior()
		add_to_group("villager")
	
	func _generate_body() -> void:
		mesh_container = Node3D.new()
		add_child(mesh_container)
		
		var skin = appearance.get("skin_color", Color(0.85, 0.7, 0.55))
		var clothes = appearance.get("clothes_color", Color(0.3, 0.25, 0.2))
		
		# Torso
		mesh_container.add_child(_create_part(Vector3(-0.12, 0.45, -0.06), Vector3(0.24, 0.4, 0.12), clothes))
		
		# Cabeza
		mesh_container.add_child(_create_part(Vector3(-0.1, 0.85, -0.05), Vector3(0.2, 0.2, 0.1), skin))
		
		# Sombrero
		mesh_container.add_child(_create_part(Vector3(-0.12, 1.03, -0.07), Vector3(0.24, 0.06, 0.14), Color(0.2, 0.15, 0.1)))
		
		# Piernas
		var ll = Node3D.new()
		ll.position = Vector3(-0.06, 0.45, 0)
		mesh_container.add_child(ll)
		ll.add_child(_create_part(Vector3(-0.04, -0.45, -0.04), Vector3(0.08, 0.45, 0.08), clothes.darkened(0.15)))
		body_parts["left_leg"] = ll
		
		var rl = Node3D.new()
		rl.position = Vector3(0.06, 0.45, 0)
		mesh_container.add_child(rl)
		rl.add_child(_create_part(Vector3(-0.04, -0.45, -0.04), Vector3(0.08, 0.45, 0.08), clothes.darkened(0.15)))
		body_parts["right_leg"] = rl
		
		# Brazos
		var la = Node3D.new()
		la.position = Vector3(-0.16, 0.8, 0)
		mesh_container.add_child(la)
		la.add_child(_create_part(Vector3(-0.03, -0.35, -0.03), Vector3(0.06, 0.35, 0.06), skin))
		body_parts["left_arm"] = la
		
		var ra = Node3D.new()
		ra.position = Vector3(0.16, 0.8, 0)
		mesh_container.add_child(ra)
		ra.add_child(_create_part(Vector3(-0.03, -0.35, -0.03), Vector3(0.06, 0.35, 0.06), skin))
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
			var c = color if i == 4 else color.darkened(0.1 + i * 0.03)
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
	
	func _start_behavior() -> void:
		current_state = 0
		state_timer = randf_range(3.0, 8.0)
	
	func _physics_process(delta: float) -> void:
		if not is_alive:
			return
		
		state_timer -= delta
		if state_timer <= 0:
			_change_state()
		
		_execute_state(delta)
		_animate(delta)
	
	func _change_state() -> void:
		if randf() < 0.4:
			current_state = 1  # WANDERING
			_pick_wander_target()
		else:
			current_state = 0  # IDLE
		state_timer = randf_range(4.0, 12.0)
	
	func _execute_state(delta: float) -> void:
		if current_state == 1:
			_wander(delta)
	
	func _pick_wander_target() -> void:
		wander_target = home_position + Vector3(randf_range(-8, 8), 0, randf_range(-8, 8))
	
	func _wander(delta: float) -> void:
		var dir = (wander_target - global_position).normalized()
		dir.y = 0
		
		velocity = dir * movement_speed
		move_and_slide()
		
		if global_position.distance_to(wander_target) < 1.0:
			current_state = 0
		
		if velocity.length() > 0.1:
			rotation.y = lerp_angle(rotation.y, atan2(dir.x, dir.z), 5 * delta)
	
	func _animate(delta: float) -> void:
		var speed = velocity.length()
		if speed > 0.1:
			animation_time += delta * 5.0
			var swing = sin(animation_time) * 0.35
			
			if body_parts.has("left_leg"):
				body_parts["left_leg"].rotation.x = swing
			if body_parts.has("right_leg"):
				body_parts["right_leg"].rotation.x = -swing
			if body_parts.has("left_arm"):
				body_parts["left_arm"].rotation.x = -swing * 0.6
			if body_parts.has("right_arm"):
				body_parts["right_arm"].rotation.x = swing * 0.6
		else:
			animation_time = 0.0
			for key in body_parts:
				body_parts[key].rotation.x = lerp(body_parts[key].rotation.x, 0.0, delta * 6)
	
	func take_damage(_amount: float) -> void:
		die()
	
	func die() -> void:
		if not is_alive:
			return
		is_alive = false
		print("[VILLAGER] ", display_name, " ha muerto")
		
		# Efecto visual simple: caer
		var tween = create_tween()
		tween.tween_property(mesh_container, "rotation:x", -PI/2, 0.3)
		tween.tween_callback(queue_free).set_delay(2.0)

func initialize(world, gen, seed_value: int) -> void:
	world_data = world
	generator = gen
	rng.seed = seed_value

func spawn_villagers(parent_node: Node) -> void:
	if generator == null:
		return
	
	var spawn_positions = generator.spawn_points.npcs
	var count = mini(spawn_positions.size(), Config.MAX_VILLAGERS)
	
	for i in range(count):
		var villager = _create_villager(i, spawn_positions[i])
		parent_node.add_child(villager)
		active_villagers.append(villager)
		EventsBus.entity_spawned.emit(villager, "villager")
	
	print("[VILLAGERS] ", active_villagers.size(), " aldeanos spawneados")

func _create_villager(id: int, pos: Vector3) -> Villager:
	var villager = Villager.new()
	villager.villager_id = id
	villager.display_name = _generate_name()
	villager.appearance = _generate_appearance()
	villager.home_position = pos
	villager.global_position = pos
	
	var col = CollisionShape3D.new()
	var shape = CapsuleShape3D.new()
	shape.radius = 0.25
	shape.height = 1.2
	col.shape = shape
	col.position.y = 0.6
	villager.add_child(col)
	
	return villager

func _generate_name() -> String:
	var first = ["Earl", "Martha", "Jeb", "Ruth", "Clyde", "Agnes", "Billy", "Edna"]
	var last = ["Hollow", "Creek", "Stone", "Woods", "Ridge", "Black"]
	return first[rng.randi() % first.size()] + " " + last[rng.randi() % last.size()]

func _generate_appearance() -> Dictionary:
	return {
		"skin_color": SKIN_COLORS[rng.randi() % SKIN_COLORS.size()],
		"clothes_color": CLOTHES_COLORS[rng.randi() % CLOTHES_COLORS.size()]
	}
