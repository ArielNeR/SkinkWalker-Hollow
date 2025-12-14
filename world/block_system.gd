# res://world/block_system.gd
extends RefCounted
class_name BlockSystem

# ═══════════════════════════════════════════════════════════════
# SISTEMA DE BLOQUES
# Define la lógica base de cada bloque del mundo
# Clase estática con métodos de utilidad
# ═══════════════════════════════════════════════════════════════

# --- PROPIEDADES DE BLOQUES ---
static var block_properties: Dictionary = {
	Config.BlockType.LANTERN: {"emits_light": true, "light_radius": 5},
	Config.BlockType.DOOR: {"interactable": true, "can_open": true},
	Config.BlockType.WATER: {"slows_movement": true, "speed_modifier": 0.5}
}

# --- OBTENER COLOR DE BLOQUE ---
static func get_block_color(block_type: int) -> Color:
	if Config.PALETTE.has(block_type):
		return Config.PALETTE[block_type]
	return Color.MAGENTA

# --- VERIFICAR SI BLOQUE ES SÓLIDO ---
static func is_solid(block_type: int) -> bool:
	match block_type:
		Config.BlockType.AIR, Config.BlockType.WATER:
			return false
		_:
			return true

# --- VERIFICAR SI BLOQUE EMITE LUZ ---
static func emits_light(block_type: int) -> bool:
	return block_type == Config.BlockType.LANTERN

# --- VERIFICAR SI BLOQUE ES TRANSPARENTE ---
static func is_transparent(block_type: int) -> bool:
	match block_type:
		Config.BlockType.AIR, Config.BlockType.GLASS, Config.BlockType.WATER:
			return true
		_:
			return false
