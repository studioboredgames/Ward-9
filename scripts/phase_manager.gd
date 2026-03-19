extends Node
## phase_manager.gd
## Responsibility: Single authority for current phase, cycle_id, and timing.
## Manages the observation cycle and phase progression.
## Contains NO player evaluation logic.

# ─── Signals ──────────────────────────────────────────────────────────────────

signal cycle_started(id: int)
signal cycle_ended(id: int)
signal phase_changed(name: String)

# ─── Constants/Config ─────────────────────────────────────────────────────────

const CYCLES_PER_PHASE: int = 3
const PHASES: Array[String] = ["shift_start", "midnight", "pre_dawn"]

# ─── Public State (Authority) ─────────────────────────────────────────────────

var current_phase_index: int = 0
var current_cycle_id: int = 0
var interaction_enabled: bool = false ## Controlled state reported via signals

# ─── Lifecycle ────────────────────────────────────────────────────────────────

func _ready() -> void:
	# Start the game loop after tree is ready
	call_deferred("_start_game")


func _start_game() -> void:
	current_phase_index = 0
	current_cycle_id = 0
	emit_signal("phase_changed", PHASES[current_phase_index])
	_start_next_cycle()

# ─── Cycle Flow ───────────────────────────────────────────────────────────────

func _start_next_cycle() -> void:
	current_cycle_id += 1
	interaction_enabled = true
	
	# Notify the router
	emit_signal("cycle_started", current_cycle_id)


## Called by game_manager when a decision is received from UI
func complete_current_cycle() -> void:
	interaction_enabled = false
	
	# Notify the router to disable interaction and log results
	emit_signal("cycle_ended", current_cycle_id)
	
	# Determine flow: next cycle or next phase
	var cycle_in_phase = (current_cycle_id - 1) % CYCLES_PER_PHASE + 1
	
	if cycle_in_phase < CYCLES_PER_PHASE:
		# Short delay for tension/pacing before next cycle
		await get_tree().create_timer(1.5).timeout
		_start_next_cycle()
	else:
		_advance_phase()

# ─── Phase Flow ───────────────────────────────────────────────────────────────

func _advance_phase() -> void:
	current_phase_index += 1
	
	if current_phase_index < PHASES.size():
		emit_signal("phase_changed", PHASES[current_phase_index])
		# Longer pause for phase transition (corridor time)
		await get_tree().create_timer(3.0).timeout
		_start_next_cycle()
	else:
		_end_shift()


func _end_shift() -> void:
	# Phase authority concludes the loop
	print("Shift completed. Finalizing evaluation...")
	# game_manager will handle the final fan-out to systems if needed
