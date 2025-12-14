# res://world/world_data.gd
extends Node
class_name WorldData

# ═══════════════════════════════════════════════════════════════
# DATOS DEL MUNDO
# Almacena todos los bloques del mundo en chunks
# Sistema optimizado para mundos cerrados
# ═══════════════════════════════════════════════════════════════

# --- ALMACENAMIENTO ---
var chunks: Dictionary = {}
var world_seed: int = 0

# ═══════════════════════════════════════════════════════════════
# CLASE CHUNK (INNER CLASS)
# ═══════════════════════════════════════════════════════════════

class ChunkData:
	var position: Vector2i
	var blocks: Array = []
	var is_dirty: bool = true
	var light_map: Array = []
	
	func _init(pos: Vector2i) -> void:
		position = pos
		_initialize_blocks()
		_initialize_light_map()
	
	func _initialize_blocks() -> void:
		blocks = []
		for x in range(Config.CHUNK_SIZE):
			var plane = []
			for y in range(Config.WORLD_HEIGHT):
				var column = []
				for z in range(Config.CHUNK_SIZE):
					column.append(Config.BlockType.AIR)
				plane.append(column)
			blocks.append(plane)
	
	func _initialize_light_map() -> void:
		light_map = []
		for x in range(Config.CHUNK_SIZE):
			var plane = []
			for y in range(Config.WORLD_HEIGHT):
				var column = []
				for z in range(Config.CHUNK_SIZE):
					column.append(Config.AMBIENT_DARKNESS)
				plane.append(column)
			light_map.append(plane)
	
	func get_block(local_x: int, local_y: int, local_z: int) -> int:
		if _is_valid_position(local_x, local_y, local_z):
			return blocks[local_x][local_y][local_z]
		return Config.BlockType.AIR
	
	func set_block(local_x: int, local_y: int, local_z: int, block_type: int) -> void:
		if _is_valid_position(local_x, local_y, local_z):
			blocks[local_x][local_y][local_z] = block_type
			is_dirty = true
	
	func _is_valid_position(x: int, y: int, z: int) -> bool:
		return (x >= 0 and x < Config.CHUNK_SIZE and
				y >= 0 and y < Config.WORLD_HEIGHT and
				z >= 0 and z < Config.CHUNK_SIZE)

# ═══════════════════════════════════════════════════════════════
# MÉTODOS PÚBLICOS
# ═══════════════════════════════════════════════════════════════

func initialize(seed_value: int) -> void:
	world_seed = seed_value
	chunks.clear()
	
	for x in range(Config.WORLD_SIZE_CHUNKS.x):
		for z in range(Config.WORLD_SIZE_CHUNKS.y):
			var chunk_pos = Vector2i(x, z)
			chunks[chunk_pos] = ChunkData.new(chunk_pos)
	
	print("[WORLD_DATA] Mundo inicializado con ", chunks.size(), " chunks")

func get_block(world_x: int, world_y: int, world_z: int) -> int:
	var chunk_pos = _world_to_chunk_pos(world_x, world_z)
	var local_pos = _world_to_local_pos(world_x, world_y, world_z)
	
	if chunks.has(chunk_pos):
		return chunks[chunk_pos].get_block(local_pos.x, local_pos.y, local_pos.z)
	return Config.BlockType.AIR

func set_block(world_x: int, world_y: int, world_z: int, block_type: int) -> void:
	var chunk_pos = _world_to_chunk_pos(world_x, world_z)
	var local_pos = _world_to_local_pos(world_x, world_y, world_z)
	
	if chunks.has(chunk_pos):
		chunks[chunk_pos].set_block(local_pos.x, local_pos.y, local_pos.z, block_type)
		EventsBus.block_changed.emit(Vector3i(world_x, world_y, world_z), block_type)

func get_chunk(chunk_pos: Vector2i):
	return chunks.get(chunk_pos, null)

func _world_to_chunk_pos(world_x: int, world_z: int) -> Vector2i:
	@warning_ignore("integer_division")
	return Vector2i(world_x / Config.CHUNK_SIZE, world_z / Config.CHUNK_SIZE)

func _world_to_local_pos(world_x: int, world_y: int, world_z: int) -> Vector3i:
	return Vector3i(
		world_x % Config.CHUNK_SIZE,
		world_y,
		world_z % Config.CHUNK_SIZE
	)

func get_world_bounds() -> Dictionary:
	return {
		"min": Vector3i(0, 0, 0),
		"max": Vector3i(
			Config.WORLD_SIZE_CHUNKS.x * Config.CHUNK_SIZE,
			Config.WORLD_HEIGHT,
			Config.WORLD_SIZE_CHUNKS.y * Config.CHUNK_SIZE
		)
	}
