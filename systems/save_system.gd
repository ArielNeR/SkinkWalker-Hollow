# res://systems/save_system.gd
extends Node

# ═══════════════════════════════════════════════════════════════
# SISTEMA DE GUARDADO
# Maneja persistencia de datos del juego
# Guarda configuración y progreso básico
# ═══════════════════════════════════════════════════════════════

const SAVE_PATH: String = "user://skinwalker_save.dat"
const CONFIG_PATH: String = "user://settings.cfg"
const ENCRYPTION_KEY: String = "skinwalker_hollow_2024"

# --- DATOS DE GUARDADO ---
var save_data: Dictionary = {
	"version": "0.1.0",
	"games_played": 0,
	"games_won_hunted": 0,
	"games_won_hunter": 0,
	"total_playtime": 0.0,
	"last_seed": 0,
	"achievements": [],
	"statistics": {
		"escapes": 0,
		"deaths": 0,
		"kills_as_hunter": 0,
		"distractions_used": 0
	}
}

# --- CONFIGURACIÓN ---
var settings: Dictionary = {
	"audio": {
		"master_volume": 1.0,
		"music_volume": 0.8,
		"sfx_volume": 1.0,
		"ambient_volume": 0.7
	},
	"video": {
		"fullscreen": false,
		"vsync": true,
		"resolution_index": 0
	},
	"gameplay": {
		"camera_sensitivity": 1.0,
		"show_hints": true
	}
}

func _ready() -> void:
	load_all()
	print("[SAVE] Sistema de guardado inicializado")

# ═══════════════════════════════════════════════════════════════
# GUARDADO DE DATOS
# ═══════════════════════════════════════════════════════════════

func save_game_data() -> bool:
	var file = FileAccess.open_encrypted_with_pass(SAVE_PATH, FileAccess.WRITE, ENCRYPTION_KEY)
	
	if file == null:
		# Fallback sin encriptación
		file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
		if file == null:
			push_error("[SAVE] No se pudo abrir archivo de guardado")
			return false
	
	var json_string = JSON.stringify(save_data)
	file.store_string(json_string)
	file.close()
	
	print("[SAVE] Datos guardados exitosamente")
	return true

func load_game_data() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		print("[SAVE] No existe archivo de guardado, usando valores por defecto")
		return false
	
	var file = FileAccess.open_encrypted_with_pass(SAVE_PATH, FileAccess.READ, ENCRYPTION_KEY)
	
	if file == null:
		# Intentar sin encriptación
		file = FileAccess.open(SAVE_PATH, FileAccess.READ)
		if file == null:
			push_error("[SAVE] No se pudo leer archivo de guardado")
			return false
	
	var json_string = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	
	if parse_result != OK:
		push_error("[SAVE] Error parseando JSON: ", json.get_error_message())
		return false
	
	var loaded_data = json.get_data()
	if loaded_data is Dictionary:
		# Mergear con datos por defecto (por si hay campos nuevos)
		_merge_data(save_data, loaded_data)
		print("[SAVE] Datos cargados exitosamente")
		return true
	
	return false

func _merge_data(target: Dictionary, source: Dictionary) -> void:
	for key in source.keys():
		if target.has(key):
			if target[key] is Dictionary and source[key] is Dictionary:
				_merge_data(target[key], source[key])
			else:
				target[key] = source[key]

# ═══════════════════════════════════════════════════════════════
# CONFIGURACIÓN
# ═══════════════════════════════════════════════════════════════

func save_settings() -> bool:
	var config = ConfigFile.new()
	
	for section in settings.keys():
		for key in settings[section].keys():
			config.set_value(section, key, settings[section][key])
	
	var error = config.save(CONFIG_PATH)
	if error != OK:
		push_error("[SAVE] Error guardando configuración: ", error)
		return false
	
	print("[SAVE] Configuración guardada")
	return true

func load_settings() -> bool:
	var config = ConfigFile.new()
	var error = config.load(CONFIG_PATH)
	
	if error != OK:
		print("[SAVE] No existe configuración, usando valores por defecto")
		return false
	
	for section in settings.keys():
		for key in settings[section].keys():
			if config.has_section_key(section, key):
				settings[section][key] = config.get_value(section, key)
	
	_apply_settings()
	print("[SAVE] Configuración cargada")
	return true

func _apply_settings() -> void:
	# Aplicar configuración de audio
	if has_node("/root/AudioManager"):
		var audio = get_node("/root/AudioManager")
		audio.set_master_volume(settings.audio.master_volume)
	
	# Aplicar configuración de video
	if settings.video.fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	
	DisplayServer.window_set_vsync_mode(
		DisplayServer.VSYNC_ENABLED if settings.video.vsync else DisplayServer.VSYNC_DISABLED
	)

# ═══════════════════════════════════════════════════════════════
# CARGA INICIAL
# ═══════════════════════════════════════════════════════════════

func load_all() -> void:
	load_game_data()
	load_settings()

func save_all() -> void:
	save_game_data()
	save_settings()

# ═══════════════════════════════════════════════════════════════
# ESTADÍSTICAS
# ═══════════════════════════════════════════════════════════════

func record_game_end(victory: bool, mode: int) -> void:
	save_data.games_played += 1
	
	if victory:
		if mode == Config.GameMode.HUNTED:
			save_data.games_won_hunted += 1
			save_data.statistics.escapes += 1
		else:
			save_data.games_won_hunter += 1
			save_data.statistics.kills_as_hunter += 1
	else:
		if mode == Config.GameMode.HUNTED:
			save_data.statistics.deaths += 1
	
	save_game_data()

func add_playtime(seconds: float) -> void:
	save_data.total_playtime += seconds
	# Guardar cada 5 minutos
	if fmod(save_data.total_playtime, 300.0) < seconds:
		save_game_data()

func record_distraction_used() -> void:
	save_data.statistics.distractions_used += 1

func set_last_seed(seed_value: int) -> void:
	save_data.last_seed = seed_value
	save_game_data()

func get_last_seed() -> int:
	return save_data.last_seed

# ═══════════════════════════════════════════════════════════════
# ACCESO A SETTINGS
# ═══════════════════════════════════════════════════════════════

func get_setting(section: String, key: String, default_value = null):
	if settings.has(section) and settings[section].has(key):
		return settings[section][key]
	return default_value

func set_setting(section: String, key: String, value) -> void:
	if settings.has(section):
		settings[section][key] = value
		save_settings()
		_apply_settings()

# ═══════════════════════════════════════════════════════════════
# RESET
# ═══════════════════════════════════════════════════════════════

func reset_save_data() -> void:
	save_data = {
		"version": "0.1.0",
		"games_played": 0,
		"games_won_hunted": 0,
		"games_won_hunter": 0,
		"total_playtime": 0.0,
		"last_seed": 0,
		"achievements": [],
		"statistics": {
			"escapes": 0,
			"deaths": 0,
			"kills_as_hunter": 0,
			"distractions_used": 0
		}
	}
	save_game_data()
	print("[SAVE] Datos de guardado reseteados")

func reset_settings() -> void:
	settings = {
		"audio": {
			"master_volume": 1.0,
			"music_volume": 0.8,
			"sfx_volume": 1.0,
			"ambient_volume": 0.7
		},
		"video": {
			"fullscreen": false,
			"vsync": true,
			"resolution_index": 0
		},
		"gameplay": {
			"camera_sensitivity": 1.0,
			"show_hints": true
		}
	}
	save_settings()
	print("[SAVE] Configuración reseteada")
