# res://core/game_manager.gd
extends Node

# ═══════════════════════════════════════════════════════════════
# GAME MANAGER - SOPORTE COMPLETO PARA AMBOS MODOS
# ═══════════════════════════════════════════════════════════════

enum GameState {
	INITIALIZING,
	MAIN_MENU,
	LOADING,
	PLAYING,
	PAUSED,
	GAME_OVER,
	VICTORY
}

var current_state: int = GameState.INITIALIZING
var current_game_mode: int = Config.GameMode.HUNTED
var game_seed: int = 0

# Referencias a sistemas
var world_data = null
var procedural_generator = null
var chunk_renderer = null
var lighting_system = null
var distraction_system = null
var villager_system = null
var animal_system = null

# Referencias a entidades
var player = null
var skinwalker = null
var prey_npc = null  # Para modo cazador

var game_scene: Node = null
var entities_container: Node = null

signal state_changed(new_state: int)
signal game_ready()

func _ready() -> void:
	print("[GAME MANAGER] Autoload inicializado")
	_connect_events()

func _connect_events() -> void:
	EventsBus.game_started.connect(_on_game_started)
	EventsBus.game_ended.connect(_on_game_ended)
	EventsBus.game_paused.connect(_on_game_paused)
	EventsBus.player_died.connect(_on_player_died)
	EventsBus.player_escaped.connect(_on_player_escaped)
	EventsBus.time_expired.connect(_on_time_expired)

func _change_state(new_state: int) -> void:
	var old_state = current_state
	current_state = new_state
	print("[GAME MANAGER] ", GameState.keys()[old_state], " -> ", GameState.keys()[new_state])
	state_changed.emit(new_state)
	
	match new_state:
		GameState.PLAYING:
			_resume_game()
		GameState.PAUSED:
			_pause_game()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") and current_state == GameState.PLAYING:
		_change_state(GameState.PAUSED)

func start_new_game(mode: int, seed_value: int = 0) -> void:
	current_game_mode = mode
	game_seed = seed_value if seed_value != 0 else randi()
	
	var mode_name = "CAZADO" if mode == Config.GameMode.HUNTED else "CAZADOR"
	print("[GAME MANAGER] Nueva partida - Modo: ", mode_name, " Seed: ", game_seed)
	
	_change_state(GameState.LOADING)
	await _load_game_async()
	_change_state(GameState.PLAYING)
	EventsBus.game_started.emit(mode)

func _load_game_async() -> void:
	# Crear escena de juego
	game_scene = Node3D.new()
	game_scene.name = "GameScene"
	get_tree().root.add_child(game_scene)
	
	entities_container = Node3D.new()
	entities_container.name = "Entities"
	game_scene.add_child(entities_container)
	
	await get_tree().process_frame
	
	# WorldData
	var WorldDataScript = load("res://world/world_data.gd")
	world_data = Node.new()
	world_data.set_script(WorldDataScript)
	world_data.name = "WorldData"
	game_scene.add_child(world_data)
	world_data.initialize(game_seed)
	
	await get_tree().process_frame
	
	# Generador procedural
	var GeneratorScript = load("res://world/procedural_generator.gd")
	procedural_generator = Node.new()
	procedural_generator.set_script(GeneratorScript)
	procedural_generator.name = "ProceduralGenerator"
	game_scene.add_child(procedural_generator)
	procedural_generator.generate(world_data, game_seed)
	
	await get_tree().process_frame
	
	# Renderizador
	var RendererScript = load("res://rendering/chunk_renderer.gd")
	chunk_renderer = Node3D.new()
	chunk_renderer.set_script(RendererScript)
	chunk_renderer.name = "ChunkRenderer"
	game_scene.add_child(chunk_renderer)
	chunk_renderer.initialize(world_data)
	chunk_renderer.render_all_chunks()
	
	await get_tree().process_frame
	
	# Iluminación
	var LightingScript = load("res://rendering/lighting_system.gd")
	lighting_system = Node3D.new()
	lighting_system.set_script(LightingScript)
	lighting_system.name = "LightingSystem"
	game_scene.add_child(lighting_system)
	
	await get_tree().process_frame
	
	# Sistema de distracciones
	var DistractionScript = load("res://systems/distraction_system.gd")
	distraction_system = Node.new()
	distraction_system.set_script(DistractionScript)
	distraction_system.name = "DistractionSystem"
	game_scene.add_child(distraction_system)
	
	# Sistema de animales
	var AnimalScript = load("res://entities/animals/animal_system.gd")
	if AnimalScript:
		animal_system = Node.new()
		animal_system.set_script(AnimalScript)
		animal_system.name = "AnimalSystem"
		game_scene.add_child(animal_system)
	
	await get_tree().process_frame
	
	# Spawn según modo de juego
	if current_game_mode == Config.GameMode.HUNTED:
		_spawn_hunted_mode()
	else:
		_spawn_hunter_mode()
	
	# Cámara
	_setup_camera()
	
	await get_tree().process_frame
	game_ready.emit()
	print("[GAME MANAGER] Carga completada - Modo: ", "CAZADO" if current_game_mode == Config.GameMode.HUNTED else "CAZADOR")

func _spawn_hunted_mode() -> void:
	# Aldeanos
	var VillagerScript = load("res://entities/npcs/villager_system.gd")
	villager_system = Node.new()
	villager_system.set_script(VillagerScript)
	villager_system.name = "VillagerSystem"
	game_scene.add_child(villager_system)
	villager_system.initialize(world_data, procedural_generator, game_seed)
	villager_system.spawn_villagers(entities_container)
	
	# Animales
	if animal_system:
		animal_system.initialize(procedural_generator, game_seed)
		animal_system.spawn_animals(entities_container)
	
	# Jugador (superviviente)
	var PlayerScript = load("res://entities/player/player.gd")
	player = CharacterBody3D.new()
	player.set_script(PlayerScript)
	player.name = "Player"
	player.set_game_mode(Config.GameMode.HUNTED)
	player.add_to_group("player")
	player.global_position = procedural_generator.get_random_spawn("player")
	entities_container.add_child(player)
	
	# Skinwalker (enemigo)
	var SkinwalkerScript = load("res://entities/skinwalker/skinwalker.gd")
	skinwalker = CharacterBody3D.new()
	skinwalker.set_script(SkinwalkerScript)
	skinwalker.name = "Skinwalker"
	skinwalker.global_position = procedural_generator.get_random_spawn("skinwalker")
	entities_container.add_child(skinwalker)

func _spawn_hunter_mode() -> void:
	# ═══════════════════════════════════════════════════════════
	# MODO CAZADOR: El jugador ES el Skinwalker
	# ═══════════════════════════════════════════════════════════
	
	# Aldeanos (posibles víctimas)
	var VillagerScript = load("res://entities/npcs/villager_system.gd")
	villager_system = Node.new()
	villager_system.set_script(VillagerScript)
	villager_system.name = "VillagerSystem"
	game_scene.add_child(villager_system)
	villager_system.initialize(world_data, procedural_generator, game_seed)
	villager_system.spawn_villagers(entities_container)
	
	# Animales
	if animal_system:
		animal_system.initialize(procedural_generator, game_seed)
		animal_system.spawn_animals(entities_container)
	
	# Jugador (Skinwalker controlable)
	var HunterPlayerScript = load("res://entities/player/hunter_player.gd")
	player = CharacterBody3D.new()
	player.set_script(HunterPlayerScript)
	player.name = "HunterPlayer"
	player.add_to_group("player")
	player.add_to_group("skinwalker")
	player.global_position = procedural_generator.get_random_spawn("skinwalker")
	entities_container.add_child(player)
	
	# Presa principal (NPC que debe cazar)
	_spawn_prey_npc()

func _spawn_prey_npc() -> void:
	# La presa es un aldeano especial que intenta escapar
	var PreyScript = load("res://entities/npcs/prey_npc.gd")
	if PreyScript:
		prey_npc = CharacterBody3D.new()
		prey_npc.set_script(PreyScript)
		prey_npc.name = "PreyNPC"
		prey_npc.add_to_group("prey")
		prey_npc.global_position = procedural_generator.get_random_spawn("player")
		entities_container.add_child(prey_npc)

func _setup_camera() -> void:
	var CameraScript = load("res://rendering/isometric_camera.gd")
	var camera = Camera3D.new()
	camera.set_script(CameraScript)
	camera.name = "IsometricCamera"
	camera.target = player
	game_scene.add_child(camera)

func _pause_game() -> void:
	get_tree().paused = true
	if TimeManager:
		TimeManager.pause_timer()

func _resume_game() -> void:
	get_tree().paused = false
	if TimeManager:
		TimeManager.resume_timer()

func _on_game_started(_mode: int) -> void:
	pass

func _on_game_ended(victory: bool, reason: String) -> void:
	print("[GAME MANAGER] Juego terminado: ", reason, " Victoria: ", victory)
	current_state = GameState.VICTORY if victory else GameState.GAME_OVER

func _on_game_paused(is_paused: bool) -> void:
	if is_paused:
		_change_state(GameState.PAUSED)
	else:
		_change_state(GameState.PLAYING)

func _on_player_died(_cause: String) -> void:
	if current_game_mode == Config.GameMode.HUNTED:
		EventsBus.game_ended.emit(false, "El Cambiapieles te atrapó...")
	else:
		EventsBus.game_ended.emit(false, "Has fallado en la cacería.")

func _on_player_escaped() -> void:
	if current_game_mode == Config.GameMode.HUNTED:
		EventsBus.game_ended.emit(true, "¡Escapaste del pueblo!")

func _on_time_expired() -> void:
	# Manejado por TimeManager
	pass

func restart_game() -> void:
	_cleanup_game()
	start_new_game(current_game_mode, 0)

func return_to_menu() -> void:
	_cleanup_game()
	current_state = GameState.MAIN_MENU
	state_changed.emit(GameState.MAIN_MENU)

func _cleanup_game() -> void:
	if game_scene:
		game_scene.queue_free()
		game_scene = null
	
	player = null
	skinwalker = null
	prey_npc = null
	world_data = null
	procedural_generator = null
	chunk_renderer = null
	lighting_system = null
	distraction_system = null
	villager_system = null
	animal_system = null
	
	get_tree().paused = false
