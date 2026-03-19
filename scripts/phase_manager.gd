extends Node
## phase_manager.gd
## Responsibility: Sole authority on game time, cycles, and phase progression.
## Controls interaction_enabled state and tracks cycle_id.

# ─── Signals ──────────────────────────────────────────────────────────────────

signal cycle_started(id: int)
signal cycle_ended(id: int)
signal phase_changed(name: String)

# ─── Configuration ────────────────────────────────────────────────────────────

@export var cycles_per_phase: int = 3
@export var total_phases: int = 3

# ─── Public State ─────────────────────────────────────────────────────────────

var current_cycle_id: int = 0
var current_phase_index: int = 0
var phase_names: Array[String] = ["shift_start", "midnight", "pre_dawn"]

# ─── Lifecycle ────────────────────────────────────────────────────────────────

func _ready() -> void:
	# Start the game after a brief delay for system initialization
	call_deferred("start_first_phase")


func start_first_phase() -> void:
	current_phase_index = 0
	current_cycle_id = 0
	emit_signal("phase_changed", phase_names[current_phase_index])
	_start_next_cycle()

# ─── Cycle Management ─────────────────────────────────────────────────────────

func _start_next_cycle() -> void:
	current_cycle_id += 1
	# interaction_enabled handled via game_manager signal routing typically,
	# but phase_manager is the authority that triggers the 'start' event.
	emit_signal("cycle_started", current_cycle_id)


func complete_current_cycle() -> void:
	# Authority check: end the cycle and notify everyone
	emit_signal("cycle_ended", current_cycle_id)
	
	# Decide: next cycle or next phase?
	var cycles_in_this_phase = (current_cycle_id - 1) % cycles_per_phase + 1
	
	if cycles_in_this_phase < cycles_per_phase:
		# Brief pause between cycles for tension
		await get_tree().create_timer(1.5).timeout
		_start_next_cycle()
	else:
		_advance_phase()

# ─── Phase Management ─────────────────────────────────────────────────────────

func _advance_phase() -> void:
	current_phase_index += 1
	
	if current_phase_index < total_phases:
		emit_signal("phase_changed", phase_names[current_phase_index])
		# Pause for transition (potential staff room or corridor time)
		await get_tree().create_timer(3.0).timeout
		_start_next_cycle()
	else:
		_trigger_game_end()


func _trigger_game_end() -> void:
	# Final evaluation typically handled here or in evaluation_manager
	print("Shift ended. Evaluation finalized.")
