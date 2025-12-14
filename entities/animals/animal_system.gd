# res://entities/animals/animal_system.gd
extends Node
class_name AnimalSystem

# ═══════════════════════════════════════════════════════════════
# SISTEMA DE ANIMALES - CORREGIDO: MIRAN HACIA ADELANTE
# ═══════════════════════════════════════════════════════════════

var generator = null
var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var active_animals: Array = []

const MAX_DEER: int = 4
const MAX_RABBITS: int = 6

enum AnimalType { DEER, RABBIT }

class Animal extends CharacterBody3D:
	var animal_type: int = 0
	var home_position: Vector3 = Vector3.ZERO
	var wander_target: Vector3 = Vector3.ZERO
	var movement_speed: float = 2.0
	var flee_speed: float = 6.0
	var is_fleeing: bool = false
	var state_timer: float = 0.0
	
	var animation_time: float = 0.0
	var mesh_container: Node3D = null
	var body_parts: Dictionary = {}
	
	func _ready() -> void:
		_generate_mesh()
		_start_behavior()
	
	func _generate_mesh() -> void:
		mesh_container = Node3D.new()
		add_child(mesh_container)
		
		if animal_type == 0:
			_generate_deer()
		else:
			_generate_rabbit()
	
	func _generate_deer() -> void:
		var fur = Color(0.5, 0.38, 0.28)
		var light_fur = Color(0.6, 0.5, 0.4)
		
		# ═══════════════════════════════════════════════════════════
		# CORREGIDO: Cabeza al frente (Z positivo = adelante)
		# El animal mira hacia Z+ (adelante en su sistema local)
		# ═══════════════════════════════════════════════════════════
		
		# Cuerpo (centrado, ligeramente hacia atrás)
		mesh_container.add_child(_create_part(Vector3(-0.2, 0.55, -0.3), Vector3(0.4, 0.35, 0.9), fur))
		
		# Cabeza (AL FRENTE - Z positivo)
		mesh_container.add_child(_create_part(Vector3(-0.1, 0.75, 0.5), Vector3(0.2, 0.2, 0.3), light_fur))
		
		# Cola (ATRÁS - Z negativo)
		mesh_container.add_child(_create_part(Vector3(-0.03, 0.75, -0.4), Vector3(0.06, 0.08, 0.15), fur.lightened(0.2)))
		
		# Patas (ajustadas)
		var positions = [
			Vector3(-0.15, 0.55, 0.35),   # Delantera izquierda (adelante)
			Vector3(0.08, 0.55, 0.35),    # Delantera derecha (adelante)
			Vector3(-0.15, 0.55, -0.2),   # Trasera izquierda (atrás)
			Vector3(0.08, 0.55, -0.2)     # Trasera derecha (atrás)
		]
		var keys = ["fl", "fr", "bl", "br"]
		
		for i in range(4):
			var pivot = Node3D.new()
			pivot.position = positions[i]
			mesh_container.add_child(pivot)
			pivot.add_child(_create_part(Vector3(-0.04, -0.55, -0.04), Vector3(0.08, 0.55, 0.08), fur.darkened(0.15)))
			body_parts[keys[i] + "_leg"] = pivot
	
	func _generate_rabbit() -> void:
		var fur = Color(0.55, 0.5, 0.45)
		
		# ═══════════════════════════════════════════════════════════
		# CORREGIDO: Cabeza al frente (Z positivo)
		# ═══════════════════════════════════════════════════════════
		
		# Cuerpo pequeño
		mesh_container.add_child(_create_part(Vector3(-0.08, 0.1, -0.1), Vector3(0.16, 0.12, 0.24), fur))
		
		# Cabeza (AL FRENTE)
		mesh_container.add_child(_create_part(Vector3(-0.06, 0.18, 0.1), Vector3(0.12, 0.1, 0.1), fur.lightened(0.1)))
		
		# Orejas (sobre la cabeza, al frente)
		mesh_container.add_child(_create_part(Vector3(-0.05, 0.26, 0.12), Vector3(0.03, 0.12, 0.02), fur))
		mesh_container.add_child(_create_part(Vector3(0.02, 0.26, 0.12), Vector3(0.03, 0.12, 0.02), fur))
		
		# Cola (ATRÁS)
		mesh_container.add_child(_create_part(Vector3(-0.03, 0.15, -0.14), Vector3(0.06, 0.06, 0.06), fur.lightened(0.3)))
		
		# Patas traseras
		var bl_pivot = Node3D.new()
		bl_pivot.position = Vector3(-0.05, 0.1, -0.06)
		mesh_container.add_child(bl_pivot)
		bl_pivot.add_child(_create_part(Vector3(-0.025, -0.1, -0.025), Vector3(0.05, 0.1, 0.05), fur.darkened(0.1)))
		body_parts["bl_leg"] = bl_pivot
		
		var br_pivot = Node3D.new()
		br_pivot.position = Vector3(0.05, 0.1, -0.06)
		mesh_container.add_child(br_pivot)
		br_pivot.add_child(_create_part(Vector3(-0.025, -0.1, -0.025), Vector3(0.05, 0.1, 0.05), fur.darkened(0.1)))
		body_parts["br_leg"] = br_pivot
		
		# Patas delanteras
		var fl_pivot = Node3D.new()
		fl_pivot.position = Vector3(-0.05, 0.1, 0.06)
		mesh_container.add_child(fl_pivot)
		fl_pivot.add_child(_create_part(Vector3(-0.02, -0.1, -0.02), Vector3(0.04, 0.1, 0.04), fur.darkened(0.1)))
		body_parts["fl_leg"] = fl_pivot
		
		var fr_pivot = Node3D.new()
		fr_pivot.position = Vector3(0.05, 0.1, 0.06)
		mesh_container.add_child(fr_pivot)
		fr_pivot.add_child(_create_part(Vector3(-0.02, -0.1, -0.02), Vector3(0.04, 0.1, 0.04), fur.darkened(0.1)))
		body_parts["fr_leg"] = fr_pivot
	
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
	
	func _start_behavior() -> void:
		state_timer = randf_range(3.0, 8.0)
		_pick_wander_target()
	
	func _physics_process(delta: float) -> void:
		_check_threats()
		
		state_timer -= delta
		if state_timer <= 0 and not is_fleeing:
			_pick_wander_target()
			state_timer = randf_range(4.0, 10.0)
		
		_move(delta)
		_animate(delta)
	
	func _check_threats() -> void:
		var players = get_tree().get_nodes_in_group("player")
		for player in players:
			if is_instance_valid(player):
				var dist = global_position.distance_to(player.global_position)
				if dist < 6.0:
					is_fleeing = true
					var away_dir = (global_position - player.global_position).normalized()
					wander_target = global_position + away_dir * 15
					return
		is_fleeing = false
	
	func _pick_wander_target() -> void:
		wander_target = home_position + Vector3(randf_range(-12, 12), 0, randf_range(-12, 12))
	
	func _move(delta: float) -> void:
		var speed = flee_speed if is_fleeing else movement_speed
		var dir = (wander_target - global_position).normalized()
		dir.y = 0
		
		velocity = dir * speed
		move_and_slide()
		
		if global_position.distance_to(wander_target) < 1.5:
			velocity = Vector3.ZERO
			if is_fleeing:
				is_fleeing = false
		
		# ═══════════════════════════════════════════════════════════
		# CORREGIDO: Rotar para que mire hacia donde camina
		# atan2(x, z) da la rotación correcta en Y
		# ═══════════════════════════════════════════════════════════
		if velocity.length() > 0.1:
			var target_rot = atan2(dir.x, dir.z)
			rotation.y = lerp_angle(rotation.y, target_rot, 8 * delta)
	
	func _animate(delta: float) -> void:
		var speed = velocity.length()
		if speed > 0.1:
			var anim_speed = 12.0 if is_fleeing else 6.0
			animation_time += delta * anim_speed
			var swing = sin(animation_time) * 0.4
			
			# Patas delanteras y traseras se mueven en oposición
			for key in body_parts:
				if "leg" in key:
					var mult = 1.0
					if "fl" in key or "br" in key:
						mult = 1.0
					else:
						mult = -1.0
					body_parts[key].rotation.x = swing * mult
		else:
			animation_time = 0.0
			for key in body_parts:
				body_parts[key].rotation.x = lerp(body_parts[key].rotation.x, 0.0, delta * 5)

func initialize(gen, seed_value: int) -> void:
	generator = gen
	rng.seed = seed_value

func spawn_animals(parent_node: Node) -> void:
	if generator == null:
		return
	
	for i in range(MAX_DEER):
		var pos = Vector3(
			rng.randf_range(12, 25) if rng.randf() < 0.5 else rng.randf_range(103, 116),
			6,
			rng.randf_range(12, 116)
		)
		var deer = _create_animal(AnimalType.DEER, pos)
		parent_node.add_child(deer)
		active_animals.append(deer)
	
	for i in range(MAX_RABBITS):
		var pos = Vector3(rng.randf_range(15, 113), 6, rng.randf_range(15, 113))
		var rabbit = _create_animal(AnimalType.RABBIT, pos)
		parent_node.add_child(rabbit)
		active_animals.append(rabbit)
	
	print("[ANIMALS] ", active_animals.size(), " animales spawneados")

func _create_animal(type: int, pos: Vector3) -> Animal:
	var animal = Animal.new()
	animal.animal_type = type
	animal.home_position = pos
	animal.global_position = pos
	animal.movement_speed = 1.5 if type == AnimalType.DEER else 2.5
	animal.flee_speed = 5.0 if type == AnimalType.DEER else 7.0
	
	var col = CollisionShape3D.new()
	var shape = CapsuleShape3D.new()
	if type == AnimalType.DEER:
		shape.radius = 0.3
		shape.height = 1.0
		col.position.y = 0.5
	else:
		shape.radius = 0.1
		shape.height = 0.25
		col.position.y = 0.15
	col.shape = shape
	animal.add_child(col)
	
	return animal
