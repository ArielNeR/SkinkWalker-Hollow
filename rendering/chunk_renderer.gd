# res://rendering/chunk_renderer.gd
extends Node3D
class_name ChunkRenderer

# ═══════════════════════════════════════════════════════════════
# RENDERIZADOR DE CHUNKS
# Convierte datos de bloques en meshes visuales
# Usa Config para funciones de bloques
# ═══════════════════════════════════════════════════════════════

# --- REFERENCIAS ---
var world_data = null

# --- ALMACENAMIENTO ---
var chunk_meshes: Dictionary = {}
var chunk_colliders: Dictionary = {}

# --- CONFIGURACIÓN ---
const RENDER_SCALE: float = 1.0
var block_size_world: float = 1.0

func _ready() -> void:
	block_size_world = Config.BLOCK_SIZE / 32.0
	
	EventsBus.world_generated.connect(_on_world_generated)
	EventsBus.block_changed.connect(_on_block_changed)

func initialize(world) -> void:
	world_data = world

func _on_world_generated() -> void:
	render_all_chunks()

func render_all_chunks() -> void:
	if world_data == null:
		push_error("[CHUNK_RENDERER] WorldData no inicializado")
		return
	
	print("[CHUNK_RENDERER] Renderizando todos los chunks...")
	var start_time = Time.get_ticks_msec()
	
	for chunk_pos in world_data.chunks.keys():
		_render_chunk(chunk_pos)
	
	var elapsed = Time.get_ticks_msec() - start_time
	print("[CHUNK_RENDERER] Renderizado completo en ", elapsed, "ms")

func _render_chunk(chunk_pos: Vector2i) -> void:
	var chunk = world_data.get_chunk(chunk_pos)
	if chunk == null:
		return
	
	# Limpiar mesh anterior si existe
	if chunk_meshes.has(chunk_pos):
		chunk_meshes[chunk_pos].queue_free()
	if chunk_colliders.has(chunk_pos):
		chunk_colliders[chunk_pos].queue_free()
	
	# Generar nuevo mesh
	var mesh_data = _generate_chunk_mesh(chunk, chunk_pos)
	
	if mesh_data.mesh:
		var mesh_instance = MeshInstance3D.new()
		mesh_instance.mesh = mesh_data.mesh
		mesh_instance.position = Vector3(
			chunk_pos.x * Config.CHUNK_SIZE * block_size_world,
			0,
			chunk_pos.y * Config.CHUNK_SIZE * block_size_world
		)
		add_child(mesh_instance)
		chunk_meshes[chunk_pos] = mesh_instance
	
	# Generar colisiones
	if mesh_data.collision_shapes.size() > 0:
		var static_body = StaticBody3D.new()
		static_body.position = Vector3(
			chunk_pos.x * Config.CHUNK_SIZE * block_size_world,
			0,
			chunk_pos.y * Config.CHUNK_SIZE * block_size_world
		)
		
		for shape_data in mesh_data.collision_shapes:
			var col_shape = CollisionShape3D.new()
			col_shape.shape = shape_data.shape
			col_shape.position = shape_data.position
			static_body.add_child(col_shape)
		
		add_child(static_body)
		chunk_colliders[chunk_pos] = static_body
	
	chunk.is_dirty = false

func _generate_chunk_mesh(chunk, chunk_pos: Vector2i) -> Dictionary:
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	var collision_shapes: Array = []
	var has_vertices = false
	
	for x in range(Config.CHUNK_SIZE):
		for y in range(Config.WORLD_HEIGHT):
			for z in range(Config.CHUNK_SIZE):
				var block_type = chunk.get_block(x, y, z)
				
				if block_type == Config.BlockType.AIR:
					continue
				
				var world_x = chunk_pos.x * Config.CHUNK_SIZE + x
				var world_z = chunk_pos.y * Config.CHUNK_SIZE + z
				
				var visible_faces = _get_visible_faces(world_x, y, world_z)
				
				if visible_faces.size() > 0:
					_add_block_faces(st, x, y, z, block_type, visible_faces)
					has_vertices = true
					
					# Usar Config en lugar de BlockSystem
					if Config.is_block_solid(block_type):
						var box = BoxShape3D.new()
						box.size = Vector3.ONE * block_size_world
						collision_shapes.append({
							"shape": box,
							"position": Vector3(x + 0.5, y + 0.5, z + 0.5) * block_size_world
						})
	
	var mesh: ArrayMesh = null
	if has_vertices:
		st.generate_normals()
		mesh = st.commit()
	
	return {
		"mesh": mesh,
		"collision_shapes": collision_shapes
	}

func _get_visible_faces(world_x: int, world_y: int, world_z: int) -> Array:
	var visible = []
	
	if _is_face_visible(world_x, world_y + 1, world_z):
		visible.append("top")
	if _is_face_visible(world_x, world_y - 1, world_z):
		visible.append("bottom")
	if _is_face_visible(world_x + 1, world_y, world_z):
		visible.append("right")
	if _is_face_visible(world_x - 1, world_y, world_z):
		visible.append("left")
	if _is_face_visible(world_x, world_y, world_z + 1):
		visible.append("front")
	if _is_face_visible(world_x, world_y, world_z - 1):
		visible.append("back")
	
	return visible

func _is_face_visible(x: int, y: int, z: int) -> bool:
	if y < 0 or y >= Config.WORLD_HEIGHT:
		return true
	
	if world_data == null:
		return true
	
	var block = world_data.get_block(x, y, z)
	# Usar Config en lugar de BlockSystem
	return block == Config.BlockType.AIR or Config.is_block_transparent(block)

func _add_block_faces(st: SurfaceTool, x: int, y: int, z: int, block_type: int, faces: Array) -> void:
	# Usar Config en lugar de BlockSystem
	var base_color = Config.get_block_color(block_type)
	var pos = Vector3(x, y, z) * block_size_world
	var size = block_size_world
	
	for face in faces:
		var color = base_color
		var vertices: Array = []
		
		match face:
			"top":
				color = base_color.lightened(0.15)
				vertices = [
					pos + Vector3(0, size, 0),
					pos + Vector3(size, size, 0),
					pos + Vector3(size, size, size),
					pos + Vector3(0, size, size)
				]
			"bottom":
				color = base_color.darkened(0.3)
				vertices = [
					pos + Vector3(0, 0, size),
					pos + Vector3(size, 0, size),
					pos + Vector3(size, 0, 0),
					pos + Vector3(0, 0, 0)
				]
			"right":
				color = base_color.darkened(0.1)
				vertices = [
					pos + Vector3(size, 0, 0),
					pos + Vector3(size, size, 0),
					pos + Vector3(size, size, size),
					pos + Vector3(size, 0, size)
				]
			"left":
				color = base_color.darkened(0.15)
				vertices = [
					pos + Vector3(0, 0, size),
					pos + Vector3(0, size, size),
					pos + Vector3(0, size, 0),
					pos + Vector3(0, 0, 0)
				]
			"front":
				color = base_color.darkened(0.05)
				vertices = [
					pos + Vector3(0, 0, size),
					pos + Vector3(size, 0, size),
					pos + Vector3(size, size, size),
					pos + Vector3(0, size, size)
				]
			"back":
				color = base_color.darkened(0.2)
				vertices = [
					pos + Vector3(size, 0, 0),
					pos + Vector3(0, 0, 0),
					pos + Vector3(0, size, 0),
					pos + Vector3(size, size, 0)
				]
		
		if vertices.size() == 4:
			st.set_color(color)
			st.add_vertex(vertices[0])
			st.add_vertex(vertices[1])
			st.add_vertex(vertices[2])
			st.add_vertex(vertices[0])
			st.add_vertex(vertices[2])
			st.add_vertex(vertices[3])

func _on_block_changed(world_pos: Vector3i, _new_type: int) -> void:
	@warning_ignore("integer_division")
	var chunk_pos = Vector2i(
		world_pos.x / Config.CHUNK_SIZE,
		world_pos.z / Config.CHUNK_SIZE
	)
	_render_chunk(chunk_pos)
	
	if world_pos.x % Config.CHUNK_SIZE == 0:
		_render_chunk(chunk_pos + Vector2i(-1, 0))
	if world_pos.x % Config.CHUNK_SIZE == Config.CHUNK_SIZE - 1:
		_render_chunk(chunk_pos + Vector2i(1, 0))
	if world_pos.z % Config.CHUNK_SIZE == 0:
		_render_chunk(chunk_pos + Vector2i(0, -1))
	if world_pos.z % Config.CHUNK_SIZE == Config.CHUNK_SIZE - 1:
		_render_chunk(chunk_pos + Vector2i(0, 1))
