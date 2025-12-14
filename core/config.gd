# res://core/config.gd
extends Node

# ═══════════════════════════════════════════════════════════════
# CONFIGURACIÓN GLOBAL DEL JUEGO - AUTOLOAD
# TIEMPOS AJUSTADOS PARA MEJOR GAMEPLAY
# ═══════════════════════════════════════════════════════════════

# --- CONFIGURACIÓN DE BLOQUES ---
const BLOCK_SIZE: int = 32
const CHUNK_SIZE: int = 16
const WORLD_HEIGHT: int = 32

# --- CONFIGURACIÓN DEL MUNDO ---
const WORLD_SIZE_CHUNKS: Vector2i = Vector2i(8, 8)
const VILLAGE_CENTER_OFFSET: Vector2i = Vector2i(4, 4)

# --- CONFIGURACIÓN DE TIEMPO (AJUSTADO) ---
const GAME_DURATION_SECONDS: float = 600.0  # 10 minutos total
const TENSION_PHASE_1: float = 60.0         # 1 min - "Algo no está bien"
const TENSION_PHASE_2: float = 180.0        # 3 min - "Te están cazando"
const TENSION_PHASE_3: float = 420.0        # 7 min - "CORRE"

# --- MODOS DE JUEGO ---
enum GameMode {
	HUNTED = 0,
	HUNTER = 1,
	UNDEFINED = 2
}

# --- TIPOS DE BLOQUES ---
enum BlockType {
	AIR = 0,
	DIRT = 1,
	STONE = 2,
	WOOD = 3,
	WOOD_PLANK = 4,
	GLASS = 5,
	ROAD = 6,
	ROOF = 7,
	GRASS = 8,
	WATER = 9,
	LANTERN = 10,
	DOOR = 11,
	FENCE = 12,
	LEAVES = 13,      # NUEVO: Hojas de árbol
	TREE_TRUNK = 14   # NUEVO: Tronco de árbol
}

# --- PALETA DE COLORES ---
var PALETTE: Dictionary = {
	BlockType.AIR: Color(0, 0, 0, 0),
	BlockType.DIRT: Color(0.35, 0.22, 0.12),
	BlockType.STONE: Color(0.4, 0.38, 0.35),
	BlockType.WOOD: Color(0.45, 0.28, 0.15),
	BlockType.WOOD_PLANK: Color(0.55, 0.38, 0.2),
	BlockType.GLASS: Color(0.4, 0.5, 0.6, 0.4),
	BlockType.ROAD: Color(0.3, 0.28, 0.25),
	BlockType.ROOF: Color(0.25, 0.15, 0.1),
	BlockType.GRASS: Color(0.2, 0.35, 0.15),
	BlockType.WATER: Color(0.15, 0.25, 0.4, 0.8),
	BlockType.LANTERN: Color(1.0, 0.8, 0.4),
	BlockType.DOOR: Color(0.4, 0.25, 0.12),
	BlockType.FENCE: Color(0.4, 0.25, 0.12),
	BlockType.LEAVES: Color(0.15, 0.4, 0.12),      # Verde oscuro
	BlockType.TREE_TRUNK: Color(0.3, 0.18, 0.08)   # Marrón oscuro
}

# --- CONFIGURACIÓN DE ILUMINACIÓN ---
const AMBIENT_DARKNESS: float = 0.25  # Más claro (antes 0.08)
const LIGHT_RADIUS_LANTERN: int = 6
const PLAYER_LIGHT_RADIUS: int = 4

# --- CONFIGURACIÓN DE ENTIDADES ---
const MAX_VILLAGERS: int = 8
const MAX_CREATURES: int = 4
const SKINWALKER_SPEED_BASE: float = 70.0
const SKINWALKER_SPEED_PHASE3: float = 130.0
const PLAYER_SPEED: float = 100.0

# --- PLATAFORMA ---
var is_mobile: bool = false
var current_platform: String = "PC"

func _ready() -> void:
	_detect_platform()
	print("[CONFIG] Autoload inicializado - Plataforma: ", current_platform)

func _detect_platform() -> void:
	var os_name = OS.get_name()
	if os_name == "Android" or os_name == "iOS":
		is_mobile = true
		current_platform = "MOBILE"
	else:
		is_mobile = false
		current_platform = "PC"

# ═══════════════════════════════════════════════════════════════
# FUNCIONES DE UTILIDAD PARA BLOQUES
# ═══════════════════════════════════════════════════════════════

func get_block_color(block_type: int) -> Color:
	if PALETTE.has(block_type):
		return PALETTE[block_type]
	return Color.MAGENTA

func is_block_solid(block_type: int) -> bool:
	match block_type:
		BlockType.AIR, BlockType.WATER:
			return false
		_:
			return true

func is_block_transparent(block_type: int) -> bool:
	match block_type:
		BlockType.AIR, BlockType.GLASS, BlockType.WATER, BlockType.LEAVES:
			return true
		_:
			return false

func block_emits_light(block_type: int) -> bool:
	return block_type == BlockType.LANTERN
