# res://world/procedural_generator.gd
extends Node
class_name ProceduralGenerator

# ═══════════════════════════════════════════════════════════════
# GENERADOR PROCEDURAL DEL PUEBLO - CASAS MEJORADAS VISUALMENTE
# CON ÁRBOLES EN BORDES Y ESTRUCTURAS MÁS RECONOCIBLES
# ═══════════════════════════════════════════════════════════════
var world_data = null
var rng: RandomNumberGenerator = RandomNumberGenerator.new()
const MIN_HOUSES: int = 5
const MAX_HOUSES: int = 8
const HOUSE_MIN_SIZE: Vector2i = Vector2i(6, 6)
const HOUSE_MAX_SIZE: Vector2i = Vector2i(10, 8)
enum ZoneType { RESIDENTIAL, CHURCH, CEMETERY, FOREST_EDGE, ABANDONED, WATER_WELL, BARN }
var generated_houses: Array = []
var generated_roads: Array = []
var special_zones: Dictionary = {}
var spawn_points: Dictionary = {
	"player": [],
	"skinwalker": [],
	"npcs": [],
	"escape_routes": []
}

func generate(world, seed_value: int) -> void:
	world_data = world
	rng.seed = seed_value
	generated_houses.clear()
	generated_roads.clear()
	special_zones.clear()
	spawn_points = {"player": [], "skinwalker": [], "npcs": [], "escape_routes": []}
	print("[GENERATOR] Iniciando generación con seed: ", seed_value)
	_generate_terrain()
	_generate_forest_borders()
	_generate_road_network()
	_generate_houses()
	_generate_special_zones()
	_calculate_spawn_points()
	EventsBus.world_generated.emit()
	print("[GENERATOR] Pueblo generado: ", generated_houses.size(), " casas")

func _generate_terrain() -> void:
	var bounds = world_data.get_world_bounds()
	for x in range(bounds.max.x):
		for z in range(bounds.max.z):
			for y in range(4):
				world_data.set_block(x, y, z, Config.BlockType.DIRT)
			world_data.set_block(x, 4, z, Config.BlockType.GRASS)

func _generate_forest_borders() -> void:
	var bounds = world_data.get_world_bounds()
	var border_depth = 6
	for x in range(bounds.max.x):
		for z in range(bounds.max.z):
			var dist_from_edge = mini(
				mini(x, bounds.max.x - 1 - x),
				mini(z, bounds.max.z - 1 - z)
			)
			if dist_from_edge < border_depth:
				var tree_chance = 0.4 - (dist_from_edge * 0.05)
				if rng.randf() < tree_chance:
					_place_tree(x, z)

func _place_tree(x: int, z: int) -> void:
	var base_y = 5
	var trunk_height = rng.randi_range(4, 7)
	var canopy_radius = rng.randi_range(2, 3)
	for y in range(base_y, base_y + trunk_height):
		world_data.set_block(x, y, z, Config.BlockType.TREE_TRUNK)
	var canopy_center_y = base_y + trunk_height
	for dx in range(-canopy_radius, canopy_radius + 1):
		for dy in range(-1, canopy_radius + 1):
			for dz in range(-canopy_radius, canopy_radius + 1):
				var dist = sqrt(dx*dx + dy*dy*0.5 + dz*dz)
				if dist <= canopy_radius:
					var lx = x + dx
					var ly = canopy_center_y + dy
					var lz = z + dz
					if world_data.get_block(lx, ly, lz) == Config.BlockType.AIR:
						if rng.randf() > 0.15:
							world_data.set_block(lx, ly, lz, Config.BlockType.LEAVES)

func _generate_road_network() -> void:
	var bounds = world_data.get_world_bounds()
	var center_x = bounds.max.x / 2
	var center_z = bounds.max.z / 2
	var main_road_z = center_z + rng.randi_range(-3, 3)
	_create_road(Vector2i(12, main_road_z), Vector2i(bounds.max.x - 12, main_road_z), 3)
	var num_secondary = rng.randi_range(2, 3)
	for i in range(num_secondary):
		@warning_ignore("integer_division")
		var road_x = 20 + i * ((bounds.max.x - 40) / num_secondary) + rng.randi_range(-2, 2)
		var start_z = main_road_z - rng.randi_range(8, 15)
		var end_z = main_road_z + rng.randi_range(8, 15)
		_create_road(Vector2i(road_x, start_z), Vector2i(road_x, end_z), 2)

func _create_road(start: Vector2i, end: Vector2i, width: int) -> void:
	generated_roads.append({"start": start, "end": end, "width": width})
	var dir = (Vector2(end) - Vector2(start)).normalized()
	var length = Vector2(start).distance_to(Vector2(end))
	for i in range(int(length) + 1):
		var pos = Vector2(start) + dir * i
		@warning_ignore("integer_division")
		for w in range(-width/2, width/2 + 1):
			var offset = Vector2(-dir.y, dir.x) * w
			var road_pos = pos + offset
			var rx = int(road_pos.x)
			var rz = int(road_pos.y)
			for y in range(4, 15):
				if world_data.get_block(rx, y, rz) != Config.BlockType.AIR:
					world_data.set_block(rx, y, rz, Config.BlockType.AIR)
			world_data.set_block(rx, 4, rz, Config.BlockType.ROAD)

func _generate_houses() -> void:
	var num_houses = rng.randi_range(MIN_HOUSES, MAX_HOUSES)
	var attempts = 0
	while generated_houses.size() < num_houses and attempts < 50:
		attempts += 1
		var size = Vector2i(
			rng.randi_range(HOUSE_MIN_SIZE.x, HOUSE_MAX_SIZE.x),
			rng.randi_range(HOUSE_MIN_SIZE.y, HOUSE_MAX_SIZE.y)
		)
		var pos = _find_valid_house_position(size)
		if pos != Vector2i(-1, -1):
			_build_improved_house(pos, size)

func _find_valid_house_position(size: Vector2i) -> Vector2i:
	var bounds = world_data.get_world_bounds()
	for _attempt in range(20):
		var x = rng.randi_range(15, bounds.max.x - size.x - 15)
		var z = rng.randi_range(15, bounds.max.z - size.y - 15)
		if _is_position_valid_for_house(Vector2i(x, z), size):
			return Vector2i(x, z)
	return Vector2i(-1, -1)

func _is_position_valid_for_house(pos: Vector2i, size: Vector2i) -> bool:
	for road in generated_roads:
		var road_rect = Rect2i(road.start - Vector2i(3, 3), Vector2i(abs(road.end.x - road.start.x) + 6, abs(road.end.y - road.start.y) + 6))
		var house_rect = Rect2i(pos, size)
		if road_rect.intersects(house_rect):
			return false
	for house in generated_houses:
		var existing_rect = Rect2i(house.position - Vector2i(3, 3), house.size + Vector2i(6, 6))
		var new_rect = Rect2i(pos, size)
		if existing_rect.intersects(new_rect):
			return false
	return true

func _build_improved_house(pos: Vector2i, size: Vector2i) -> void:
	var height = rng.randi_range(4, 5)
	var base_y = 5
	var has_lantern = rng.randf() > 0.3
	var effective_size = size + Vector2i(2, 2)

	for x in range(pos.x - 2, pos.x + effective_size.x + 2):
		for z in range(pos.y - 2, pos.y + effective_size.y + 2):
			for y in range(base_y, base_y + height + 4):
				world_data.set_block(x, y, z, Config.BlockType.AIR)

	for x in range(pos.x - 1, pos.x + effective_size.x + 1):
		for z in range(pos.y - 1, pos.y + effective_size.y + 1):
			world_data.set_block(x, base_y - 1, z, Config.BlockType.STONE)

	for y in range(base_y, base_y + 1):
		for x in range(pos.x, pos.x + effective_size.x):
			for z in range(pos.y, pos.y + effective_size.y):
				world_data.set_block(x, y, z, Config.BlockType.WOOD_PLANK)

	for y in range(base_y + 1, base_y + height):
		for x in range(pos.x - 1, pos.x + effective_size.x + 1):
			for z in range(pos.y - 1, pos.y + effective_size.y + 1):
				if x == pos.x - 1 or x == pos.x + effective_size.x or z == pos.y - 1 or z == pos.y + effective_size.y:
					world_data.set_block(x, y, z, Config.BlockType.WOOD)
				elif (x == pos.x or x == pos.x + effective_size.x - 1 or z == pos.y or z == pos.y + effective_size.y - 1):
					if y != base_y + 1:
						world_data.set_block(x, y, z, Config.BlockType.WOOD_PLANK)

		if y == base_y + 2:
			var window_x = pos.x + effective_size.x/2 - 1
			world_data.set_block(window_x, y, pos.y - 1, Config.BlockType.GLASS)
			world_data.set_block(window_x, y, pos.y, Config.BlockType.GLASS)
			world_data.set_block(window_x + 1, y, pos.y - 1, Config.BlockType.GLASS)
			world_data.set_block(window_x + 1, y, pos.y, Config.BlockType.GLASS)

			world_data.set_block(window_x, y, pos.y + effective_size.y, Config.BlockType.GLASS)
			world_data.set_block(window_x, y, pos.y + effective_size.y - 1, Config.BlockType.GLASS)
			world_data.set_block(window_x + 1, y, pos.y + effective_size.y, Config.BlockType.GLASS)
			world_data.set_block(window_x + 1, y, pos.y + effective_size.y - 1, Config.BlockType.GLASS)

	var door_x = pos.x + effective_size.x/2
	for y in range(base_y + 1, base_y + 3):
		world_data.set_block(door_x - 1, y, pos.y - 1, Config.BlockType.WOOD)
		world_data.set_block(door_x + 1, y, pos.y - 1, Config.BlockType.WOOD)
		world_data.set_block(door_x, y, pos.y - 1, Config.BlockType.AIR)

	var roof_height = 3
	for layer in range(roof_height + 1):
		var roof_y = base_y + height + layer
		var current_width = effective_size.x + 2 - layer*2
		var current_depth = effective_size.y + 2 - layer*2

		if current_width > 0 and current_depth > 0:
			for x in range(pos.x - 1 + layer, pos.x + effective_size.x + 1 - layer):
				for z in range(pos.y - 1 + layer, pos.y + effective_size.y + 1 - layer):
					if x == pos.x - 1 + layer or x == pos.x + effective_size.x - layer:
						world_data.set_block(x, roof_y, z, Config.BlockType.ROOF)
					if z == pos.y - 1 + layer or z == pos.y + effective_size.y - 1 - layer:
						world_data.set_block(x, roof_y, z, Config.BlockType.ROOF)

	if rng.randf() > 0.5:
		var chimney_x = pos.x + effective_size.x - 2
		var chimney_z = pos.y + effective_size.y/2
		for y in range(base_y + height - 1, base_y + height + 2):
			world_data.set_block(chimney_x, y, chimney_z, Config.BlockType.STONE)
			world_data.set_block(chimney_x + 1, y, chimney_z, Config.BlockType.STONE)
			if y == base_y + height + 1:
				world_data.set_block(chimney_x, y + 1, chimney_z, Config.BlockType.STONE)
				world_data.set_block(chimney_x + 1, y + 1, chimney_z, Config.BlockType.STONE)

	if has_lantern:
		world_data.set_block(door_x + 2, base_y + 3, pos.y - 2, Config.BlockType.LANTERN)
		for y in range(base_y + 1, base_y + 3):
			world_data.set_block(door_x + 2, y, pos.y - 2, Config.BlockType.WOOD)

	generated_houses.append({
		"position": pos,
		"size": effective_size,
		"height": height,
		"has_lantern": has_lantern
	})

func _generate_special_zones() -> void:
	_generate_cemetery()
	if rng.randf() < 0.6:
		_generate_water_well()

func _generate_cemetery() -> void:
	var bounds = world_data.get_world_bounds()
	var pos = Vector2i(rng.randi_range(20, 35), bounds.max.z - 25)
	var size = Vector2i(8, 6)
	for x in range(pos.x, pos.x + size.x):
		world_data.set_block(x, 5, pos.y, Config.BlockType.FENCE)
		world_data.set_block(x, 5, pos.y + size.y - 1, Config.BlockType.FENCE)
	for z in range(pos.y, pos.y + size.y):
		world_data.set_block(pos.x, 5, z, Config.BlockType.FENCE)
		world_data.set_block(pos.x + size.x - 1, 5, z, Config.BlockType.FENCE)
	for i in range(rng.randi_range(4, 7)):
		var grave_x = pos.x + 2 + rng.randi_range(0, size.x - 4)
		var grave_z = pos.y + 2 + rng.randi_range(0, size.y - 4)
		world_data.set_block(grave_x, 5, grave_z, Config.BlockType.STONE)
		world_data.set_block(grave_x, 6, grave_z, Config.BlockType.STONE)
	special_zones[ZoneType.CEMETERY] = {"position": pos, "size": size}

func _generate_water_well() -> void:
	var bounds = world_data.get_world_bounds()
	var pos = Vector2i(bounds.max.x / 2 + rng.randi_range(-8, 8), bounds.max.z / 2 + rng.randi_range(-8, 8))
	for dx in range(-1, 2):
		for dz in range(-1, 2):
			if abs(dx) + abs(dz) <= 1:
				world_data.set_block(pos.x + dx, 4, pos.y + dz, Config.BlockType.WATER)
				world_data.set_block(pos.x + dx, 5, pos.y + dz, Config.BlockType.STONE)
	special_zones[ZoneType.WATER_WELL] = {"position": pos}

func _calculate_spawn_points() -> void:
	var bounds = world_data.get_world_bounds()
	spawn_points.player.append(Vector3(bounds.max.x / 2, 6, bounds.max.z / 2))
	spawn_points.skinwalker.append(Vector3(15, 6, 15))
	spawn_points.skinwalker.append(Vector3(bounds.max.x - 15, 6, bounds.max.z - 15))
	for house in generated_houses:
		spawn_points.npcs.append(Vector3(
			house.position.x + house.size.x / 2,
			6,
			house.position.y + house.size.y / 2
		))
	spawn_points.escape_routes.append(Vector3(bounds.max.x / 2, 6, 8))
	spawn_points.escape_routes.append(Vector3(8, 6, bounds.max.z / 2))

func get_random_spawn(type: String) -> Vector3:
	if spawn_points.has(type) and spawn_points[type].size() > 0:
		return spawn_points[type][rng.randi() % spawn_points[type].size()]
	return Vector3(64, 6, 64)
