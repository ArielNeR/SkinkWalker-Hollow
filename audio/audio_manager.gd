# res://audio/audio_manager.gd
extends Node

# ═══════════════════════════════════════════════════════════════
# SISTEMA DE AUDIO ATMOSFÉRICO
# Maneja sonidos ambientales, música y efectos de tensión
# Genera atmósfera de horror progresivo
# ═══════════════════════════════════════════════════════════════

# --- BUSES DE AUDIO ---
const BUS_MASTER: String = "Master"
const BUS_MUSIC: String = "Music"
const BUS_SFX: String = "SFX"
const BUS_AMBIENT: String = "Ambient"

# --- REPRODUCTORES ---
var music_player: AudioStreamPlayer
var ambient_player: AudioStreamPlayer
var sfx_players: Array[AudioStreamPlayer] = []
var tension_player: AudioStreamPlayer

# --- ESTADO ---
var current_tension_phase: int = 0
var ambient_timer: float = 0.0
var is_muted: bool = false

# --- CONFIGURACIÓN ---
const MAX_SFX_PLAYERS: int = 8
const AMBIENT_INTERVAL_MIN: float = 10.0
const AMBIENT_INTERVAL_MAX: float = 30.0

# --- SONIDOS PROCEDURALES (sin assets externos) ---
# Generamos tonos simples para la atmósfera

func _ready() -> void:
	_setup_audio_buses()
	_setup_players()
	_connect_events()
	print("[AUDIO] Sistema de audio inicializado")

func _setup_audio_buses() -> void:
	# Crear buses si no existen
	# NOTA: En producción, configurar en Project Settings > Audio
	pass

func _setup_players() -> void:
	# Reproductor de música
	music_player = AudioStreamPlayer.new()
	music_player.bus = BUS_MUSIC
	music_player.volume_db = -10.0
	add_child(music_player)
	
	# Reproductor de ambiente
	ambient_player = AudioStreamPlayer.new()
	ambient_player.bus = BUS_AMBIENT
	ambient_player.volume_db = -15.0
	add_child(ambient_player)
	
	# Reproductor de tensión (drones, latidos)
	tension_player = AudioStreamPlayer.new()
	tension_player.bus = BUS_AMBIENT
	tension_player.volume_db = -20.0
	add_child(tension_player)
	
	# Pool de reproductores SFX
	for i in range(MAX_SFX_PLAYERS):
		var player = AudioStreamPlayer.new()
		player.bus = BUS_SFX
		add_child(player)
		sfx_players.append(player)

func _connect_events() -> void:
	EventsBus.tension_phase_changed.connect(_on_tension_changed)
	EventsBus.horror_event_triggered.connect(_on_horror_event)
	EventsBus.ambient_sound_trigger.connect(_on_ambient_trigger)
	EventsBus.skinwalker_detected_player.connect(_on_chase_start)
	EventsBus.skinwalker_lost_player.connect(_on_chase_end)

func _process(delta: float) -> void:
	_update_ambient_sounds(delta)
	_update_tension_audio()

# ═══════════════════════════════════════════════════════════════
# SONIDOS AMBIENTALES
# ═══════════════════════════════════════════════════════════════

func _update_ambient_sounds(delta: float) -> void:
	ambient_timer -= delta
	
	if ambient_timer <= 0:
		_play_random_ambient()
		ambient_timer = randf_range(AMBIENT_INTERVAL_MIN, AMBIENT_INTERVAL_MAX)
		
		# Más frecuente en fases de tensión alta
		if current_tension_phase >= 2:
			ambient_timer *= 0.5

func _play_random_ambient() -> void:
	# DECISIÓN PENDIENTE: Cargar sonidos de assets
	# Por ahora, simular con tonos generados
	var sounds = [
		"wind_howl",
		"branch_crack",
		"distant_animal",
		"creaking_wood",
		"footsteps_distant",
		"whisper"
	]
	
	var selected = sounds[randi() % sounds.size()]
	_play_generated_tone(selected)

func _play_generated_tone(sound_type: String) -> void:
	# Generar tono simple según el tipo
	var stream = _create_procedural_sound(sound_type)
	if stream:
		var player = _get_free_sfx_player()
		if player:
			player.stream = stream
			player.volume_db = randf_range(-25.0, -15.0)
			player.play()

func _create_procedural_sound(sound_type: String) -> AudioStream:
	# Crear sonido procedural básico
	# NOTA: Para sonidos reales, usar AudioStreamWAV o AudioStreamOggVorbis
	
	var generator = AudioStreamGenerator.new()
	generator.mix_rate = 22050
	generator.buffer_length = 0.5
	
	# DECISIÓN PENDIENTE: Implementar generación de audio procedural
	# Por ahora retornamos null (silencio)
	return null

# ═══════════════════════════════════════════════════════════════
# MÚSICA Y TENSIÓN
# ═══════════════════════════════════════════════════════════════

func _update_tension_audio() -> void:
	# Ajustar volumen del drone de tensión según fase
	var target_volume: float
	
	match current_tension_phase:
		0:
			target_volume = -40.0  # Casi inaudible
		1:
			target_volume = -25.0  # Sutil
		2:
			target_volume = -15.0  # Notable
		3:
			target_volume = -8.0   # Intenso
		_:
			target_volume = -40.0
	
	tension_player.volume_db = lerp(tension_player.volume_db, target_volume, 0.02)

func _on_tension_changed(phase: int) -> void:
	current_tension_phase = phase
	
	match phase:
		1:
			_start_unease_ambience()
		2:
			_start_hunt_music()
		3:
			_start_desperation_music()

func _start_unease_ambience() -> void:
	# Drone bajo, inquietante
	print("[AUDIO] Iniciando ambiente de inquietud")

func _start_hunt_music() -> void:
	# Música de persecución
	print("[AUDIO] Iniciando música de caza")

func _start_desperation_music() -> void:
	# Música intensa, latidos
	print("[AUDIO] Iniciando música de desesperación")

# ═══════════════════════════════════════════════════════════════
# EVENTOS DE HORROR
# ═══════════════════════════════════════════════════════════════

func _on_horror_event(event_type: String) -> void:
	match event_type:
		"skinwalker_near":
			_play_stinger("proximity")
		"skinwalker_reveal":
			_play_stinger("reveal")
		"jumpscare":
			_play_stinger("jumpscare")
		"distant_scream":
			_play_ambient_effect("scream")
		"desperation_phase":
			_play_heartbeat()

func _play_stinger(stinger_type: String) -> void:
	print("[AUDIO] Stinger: ", stinger_type)
	# DECISIÓN PENDIENTE: Implementar stingers de audio

func _play_ambient_effect(effect: String) -> void:
	print("[AUDIO] Efecto ambiental: ", effect)

func _play_heartbeat() -> void:
	print("[AUDIO] Latidos de corazón iniciados")
	# Latidos que aumentan con el tiempo

func _on_ambient_trigger(sound_id: String) -> void:
	_play_generated_tone(sound_id)

func _on_chase_start() -> void:
	print("[AUDIO] Persecución iniciada")
	_start_hunt_music()

func _on_chase_end() -> void:
	print("[AUDIO] Persecución terminada")
	# Volver a ambiente normal gradualmente

# ═══════════════════════════════════════════════════════════════
# UTILIDADES
# ═══════════════════════════════════════════════════════════════

func _get_free_sfx_player() -> AudioStreamPlayer:
	for player in sfx_players:
		if not player.playing:
			return player
	return sfx_players[0]  # Reusar el primero si todos ocupados

func play_sfx_at_position(sound: String, position: Vector3) -> void:
	# Para sonidos 3D posicionales
	# DECISIÓN PENDIENTE: Implementar AudioStreamPlayer3D
	pass

func set_master_volume(volume: float) -> void:
	AudioServer.set_bus_volume_db(0, linear_to_db(volume))

func mute(should_mute: bool) -> void:
	is_muted = should_mute
	AudioServer.set_bus_mute(0, should_mute)
