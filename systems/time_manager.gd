# res://systems/time_manager.gd
extends Node

# ═══════════════════════════════════════════════════════════════
# SISTEMA DE TIEMPO - MENSAJES CORRECTOS SEGÚN MODO
# ═══════════════════════════════════════════════════════════════

var time_remaining: float = 600.0
var current_phase: int = 0
var is_running: bool = false
var game_mode: int = 0

enum TensionPhase { CALM, UNEASE, HUNTED, DESPERATION }

var phase_configs: Dictionary = {
	TensionPhase.CALM: {"skinwalker_aggression": 0.0},
	TensionPhase.UNEASE: {"skinwalker_aggression": 0.3},
	TensionPhase.HUNTED: {"skinwalker_aggression": 0.7},
	TensionPhase.DESPERATION: {"skinwalker_aggression": 1.0}
}

func _ready() -> void:
	print("[TIME_MANAGER] Autoload inicializado")
	EventsBus.game_started.connect(_on_game_started)

func _process(delta: float) -> void:
	if not is_running:
		return
	
	_update_time(delta)
	_check_phase_transitions()

func _update_time(delta: float) -> void:
	time_remaining -= delta
	EventsBus.time_updated.emit(time_remaining)
	
	if time_remaining <= 0:
		time_remaining = 0
		_on_time_expired()

func _check_phase_transitions() -> void:
	var new_phase = _calculate_current_phase()
	
	if new_phase != current_phase:
		current_phase = new_phase
		_on_phase_changed()

func _calculate_current_phase() -> int:
	var elapsed = Config.GAME_DURATION_SECONDS - time_remaining
	
	if elapsed < Config.TENSION_PHASE_1:
		return TensionPhase.CALM
	elif elapsed < Config.TENSION_PHASE_2:
		return TensionPhase.UNEASE
	elif elapsed < Config.TENSION_PHASE_3:
		return TensionPhase.HUNTED
	else:
		return TensionPhase.DESPERATION

func _on_phase_changed() -> void:
	EventsBus.tension_phase_changed.emit(current_phase)
	
	# Solo mostrar alertas para modo cazado
	if game_mode == Config.GameMode.HUNTED:
		match current_phase:
			TensionPhase.UNEASE:
				EventsBus.emit_notification("⚠ Algo no está bien...", "warning")
			TensionPhase.HUNTED:
				EventsBus.emit_notification("👁 ¡Te están cazando!", "danger")
			TensionPhase.DESPERATION:
				EventsBus.emit_notification("💀 ¡CORRE! ¡No queda tiempo!", "critical")

func _on_time_expired() -> void:
	is_running = false
	EventsBus.time_expired.emit()
	
	# ═══════════════════════════════════════════════════════════
	# MENSAJES CORRECTOS SEGÚN MODO
	# ═══════════════════════════════════════════════════════════
	if game_mode == Config.GameMode.HUNTED:
		# CAZADO: Sobrevivir = Victoria
		EventsBus.game_ended.emit(true, "¡Sobreviviste hasta el amanecer! El sol ahuyentó al Cambiapieles.")
	else:
		# CAZADOR: Tiempo agotado = Derrota (presa escapó implícitamente)
		EventsBus.game_ended.emit(false, "El amanecer llegó. La presa sobrevivió la noche.")

func _on_game_started(mode: int) -> void:
	game_mode = mode
	time_remaining = Config.GAME_DURATION_SECONDS
	current_phase = TensionPhase.CALM
	is_running = true
	print("[TIME] Partida iniciada. Modo: ", Config.GameMode.keys()[mode])

func get_phase_config() -> Dictionary:
	return phase_configs.get(current_phase, phase_configs[TensionPhase.CALM])

func get_skinwalker_aggression() -> float:
	return get_phase_config()["skinwalker_aggression"]

func get_formatted_time() -> String:
	var minutes = int(time_remaining) / 60
	var seconds = int(time_remaining) % 60
	return "%02d:%02d" % [minutes, seconds]

func pause_timer() -> void:
	is_running = false

func resume_timer() -> void:
	is_running = true

func get_current_phase() -> int:
	return current_phase

func get_time_remaining() -> float:
	return time_remaining
