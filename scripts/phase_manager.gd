extends Node
## phase_manager.gd
## Responsibility: Authority for loop state and aggressive time pressure.

signal cycle_started_notify(id: int)
signal cycle_ended_notify(id: int)
signal phase_changed_notify(phase_name: String)

# ─── Configuration ────────────────────────────────────────────────────────────

@export var debug_logs: bool = true
const CYCLES_PER_PHASE: int = 3
const PHASES: Array[String] = ["shift_start", "midnight", "pre_dawn"]

# Tension Scaling: Aggressive Curve 18 -> 13 -> 9
const CYCLE_TIMES: Array[float] = [18.0, 13.0, 9.0]

# ─── Public State (Authority) ─────────────────────────────────────────────────

var current_phase_index: int = 0
var current_cycle_id: int = 0
var _cycle_completed: bool = false
var _cycle_timer_active: bool = false

# ─── Lifecycle ────────────────────────────────────────────────────────────────

func _ready() -> void:
	call_deferred("_start_game")


func _start_game() -> void:
	current_phase_index = 0
	current_cycle_id = 0
	emit_signal("phase_changed_notify", PHASES[current_phase_index])
	_start_next_cycle()


# ─── Cycle Management ─────────────────────────────────────────────────────────

func _start_next_cycle() -> void:
	current_cycle_id += 1
	_cycle_completed = false
	
	var time_allowed = CYCLE_TIMES[clampi(current_phase_index, 0, 2)]
	_start_cycle_clock(current_cycle_id, time_allowed)
	
	emit_signal("cycle_started_notify", current_cycle_id)


func _start_cycle_clock(cycle_id: int, duration: float) -> void:
	# Randomize when environmental tension starts (3-6s before limit)
	var tension_buffer = randf_range(3.0, 6.0)
	var silent_time = max(0.1, duration - tension_buffer)
	
	await get_tree().create_timer(silent_time).timeout
	
	# Start Pressure (Environmental cues, no UI)
	if cycle_id == current_cycle_id and not _cycle_completed:
		_trigger_environmental_pressure()
		
		# Remaining time
		await get_tree().create_timer(tension_buffer).timeout
		
		# Final timeout
		if cycle_id == current_cycle_id and not _cycle_completed:
			_trigger_synthetic_decision()


func _trigger_environmental_pressure() -> void:
	if debug_logs: print("Phase Authority: Environmental Pressure active.")
	# EventManager and others should hook into this if needed, 
	# but for now we'll just let the lights/audio scaling handle it
	pass


func _trigger_synthetic_decision() -> void:
	var gm = get_tree().get_first_node_in_group("game_manager")
	if gm:
		gm.emit_signal("decision_received", "no_decision", null)
	else:
		_complete_current_cycle()


func _on_decision_received(_decision: String, _patient: Node = null) -> void:
	# Brief observation pause
	await get_tree().create_timer(0.3).timeout
	_complete_current_cycle()


func _complete_current_cycle() -> void:
	if _cycle_completed: return
	_cycle_completed = true
	
	emit_signal("cycle_ended_notify", current_cycle_id)
	
	var cycle_in_phase = (current_cycle_id - 1) % CYCLES_PER_PHASE + 1
	if cycle_in_phase < CYCLES_PER_PHASE:
		await get_tree().create_timer(1.2).timeout
		_start_next_cycle()
	else:
		_advance_phase()


func _advance_phase() -> void:
	current_phase_index += 1
	
	if current_phase_index < PHASES.size():
		emit_signal("phase_changed_notify", PHASES[current_phase_index])
		await get_tree().create_timer(2.0).timeout
		_start_next_cycle()
	else:
		print("Phase Authority: Shift completed.")
