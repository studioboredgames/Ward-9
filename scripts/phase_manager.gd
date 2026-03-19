extends Node
## phase_manager.gd
## Responsibility: Single authority for loop state (cycle_id, phase_index).
## Reacts to game_manager signals; provides authoritative status updates.

# ─── Signals (Internal Authority Notifications) ───────────────────────────────

signal cycle_started_notify(id: int)
signal cycle_ended_notify(id: int)
signal phase_changed_notify(name: String)

# ─── Configuration ────────────────────────────────────────────────────────────

const CYCLES_PER_PHASE: int = 3
const PHASES: Array[String] = ["shift_start", "midnight", "pre_dawn"]

# ─── Public State (Authority) ─────────────────────────────────────────────────

var current_phase_index: int = 0
var current_cycle_id: int = 0

# ─── Lifecycle ────────────────────────────────────────────────────────────────

func _ready() -> void:
	# Authority connects to the router to receive progress signals
	var gm = get_parent() # Assuming it's a child of Main/GameManager
	if gm.has_signal("decision_received"):
		gm.decision_received.connect(_on_decision_received)
		
	call_deferred("_start_game")


func _start_game() -> void:
	current_phase_index = 0
	current_cycle_id = 0
	emit_signal("phase_changed_notify", PHASES[current_phase_index])
	_start_next_cycle()


# ─── Cycle Management ─────────────────────────────────────────────────────────

func _start_next_cycle() -> void:
	current_cycle_id += 1
	emit_signal("cycle_started_notify", current_cycle_id)


func _on_decision_received(_decision: String) -> void:
	_complete_current_cycle()


func _complete_current_cycle() -> void:
	emit_signal("cycle_ended_notify", current_cycle_id)
	
	# Determine flow
	var cycle_in_phase = (current_cycle_id - 1) % CYCLES_PER_PHASE + 1
	
	if cycle_in_phase < CYCLES_PER_PHASE:
		await get_tree().create_timer(1.5).timeout
		_start_next_cycle()
	else:
		_advance_phase()

# ─── Phase Management ─────────────────────────────────────────────────────────

func _advance_phase() -> void:
	current_phase_index += 1
	
	if current_phase_index < PHASES.size():
		emit_signal("phase_changed_notify", PHASES[current_phase_index])
		await get_tree().create_timer(3.0).timeout
		_start_next_cycle()
	else:
		_end_shift()


func _end_shift() -> void:
	print("Phase Authority: Shift completed.")
