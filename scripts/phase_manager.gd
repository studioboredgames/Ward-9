extends Node
## phase_manager.gd
## Responsibility: Single authority for loop state (cycle_id, phase_index).
## Reacts to game_manager signals; provides authoritative status updates.

# ─── Signals (Internal Authority Notifications) ───────────────────────────────

signal cycle_started_notify(id: int)
signal cycle_ended_notify(id: int)
signal phase_changed_notify(phase_name: String)

# ─── Configuration ────────────────────────────────────────────────────────────

@export var debug_logs: bool = true
const CYCLES_PER_PHASE: int = 3
const PHASES: Array[String] = ["shift_start", "midnight", "pre_dawn"]
const CYCLE_TIMEOUT: float = 30.0 ## Seconds before auto-completing cycle

# ─── Public State (Authority) ─────────────────────────────────────────────────

var current_phase_index: int = 0
var current_cycle_id: int = 0
var _cycle_completed: bool = false

# ─── Lifecycle ────────────────────────────────────────────────────────────────

func _ready() -> void:
	# Timing Fix: Defer connection to ensure GameManager exists in group
	call_deferred("_connect_to_game_manager")
	call_deferred("_start_game")


func _connect_to_game_manager() -> void:
	# Note: gm now connects to US via its _connect_signals loop
	pass


func _start_game() -> void:
	current_phase_index = 0
	current_cycle_id = 0
	emit_signal("phase_changed_notify", PHASES[current_phase_index])
	_start_next_cycle()


# ─── Cycle Management ─────────────────────────────────────────────────────────

func _start_next_cycle() -> void:
	current_cycle_id += 1
	_cycle_completed = false
	_start_cycle_timeout(current_cycle_id)
	emit_signal("cycle_started_notify", current_cycle_id)


func _start_cycle_timeout(cycle_id: int) -> void:
	# Failure Path Fix: Prevent soft locks if player doesn't decide
	await get_tree().create_timer(CYCLE_TIMEOUT).timeout
	
	# Validity Check: Only complete if this specific cycle is still active
	if cycle_id == current_cycle_id and not _cycle_completed:
		if debug_logs: print("Phase Authority: Cycle timeout reached. Emitting synthetic decision.")
		_trigger_synthetic_decision()


func _trigger_synthetic_decision() -> void:
	var gm = get_tree().get_first_node_in_group("game_manager")
	if gm:
		# Use "All Normal" as safest fallback, or a specific "no_decision" value
		if gm.has_signal("decision_received"):
			gm.emit_signal("decision_received", "no_decision", null)
	else:
		# Fail-safe: complete locally if router is lost
		_complete_current_cycle()


func _on_decision_received(_decision: String, _patient: Node = null) -> void:
	# Design: Brief cooldown BEFORE processing completion
	# Gives event_manager time to react to the decision itself (tension)
	await get_tree().create_timer(0.3).timeout
	_complete_current_cycle()


func _complete_current_cycle() -> void:
	# Race Condition Fix: Prevent double-completion (Decision vs Timeout)
	if _cycle_completed:
		return
	_cycle_completed = true
	
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
	if debug_logs: print("Phase Authority: Shift completed.")
