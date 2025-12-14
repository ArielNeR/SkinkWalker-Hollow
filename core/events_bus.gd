# res://core/events_bus.gd
extends Node

# ═══════════════════════════════════════════════════════════════
# BUS DE EVENTOS GLOBAL - AUTOLOAD
# Sistema desacoplado de comunicación entre sistemas
# Accesible globalmente como: EventsBus.signal_name.emit()
# ═══════════════════════════════════════════════════════════════

# --- SEÑALES DE JUEGO ---
signal game_started(mode: int)
signal game_ended(victory: bool, reason: String)
signal game_paused(is_paused: bool)

# --- SEÑALES DE TIEMPO Y TENSIÓN ---
signal time_updated(seconds_remaining: float)
signal tension_phase_changed(phase: int)
signal time_expired()

# --- SEÑALES DEL MUNDO ---
signal world_generated()
signal chunk_loaded(chunk_pos: Vector2i)
signal block_changed(world_pos: Vector3i, new_type: int)

# --- SEÑALES DE ENTIDADES ---
signal player_spawned(player_node: Node)
signal player_died(cause: String)
signal player_escaped()
signal entity_spawned(entity: Node, entity_type: String)
signal entity_died(entity: Node)

# --- SEÑALES DEL CAMBIAPIELES ---
signal skinwalker_spawned()
signal skinwalker_transformed(into_what: String)
signal skinwalker_detected_player()
signal skinwalker_lost_player()
signal skinwalker_killed_target(target: Node)

# --- SEÑALES DE DISTRACCIONES ---
signal distraction_created(position: Vector3, type_name: String, by_whom: String)
signal distraction_triggered(position: Vector3)
signal disguise_activated(entity: Node, disguise_type: String)
signal disguise_broken(entity: Node)

# --- SEÑALES DE NPC ---
signal npc_behavior_changed(npc: Node, new_state: String)
signal npc_suspicious_activity(npc: Node)
signal npc_replaced_by_skinwalker(npc: Node)

# --- SEÑALES DE AUDIO/ATMÓSFERA ---
signal ambient_sound_trigger(sound_id: String)
signal horror_event_triggered(event_type: String)

# --- SEÑALES DE UI ---
signal ui_notification(message: String, type: String)
signal objective_updated(objective_text: String)

func _ready() -> void:
	print("[EVENTS_BUS] Autoload inicializado")

# ═══════════════════════════════════════════════════════════════
# MÉTODOS DE UTILIDAD
# ═══════════════════════════════════════════════════════════════

func emit_notification(message: String, type: String = "info") -> void:
	ui_notification.emit(message, type)

func emit_horror_event(event_type: String) -> void:
	horror_event_triggered.emit(event_type)
	print("[EVENT] Horror event: ", event_type)
