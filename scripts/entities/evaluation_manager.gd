extends Node
## evaluation_manager.gd
## Responsibility: Score player behavior and track psychological hesitation.
## Implements: Mistake counter with delayed feedback and hesitation metrics.

signal evaluation_updated(state: String, cycle_id: int)
signal decision_resolved(correct: bool) 

# ─── Configuration ────────────────────────────────────────────────────────────

@export var fail_threshold: float = 0.8

# ─── State ────────────────────────────────────────────────────────────────────

var mistake_count: int = 0
var _total_cycles: int = 0
var _cycle_start_time: float = 0.0

# ─── Lifecycle ────────────────────────────────────────────────────────────────

func _ready() -> void:
	add_to_group("evaluation_manager")


func reset_cycle_timer() -> void:
	_cycle_start_time = Time.get_ticks_msec() / 1000.0

# ─── Public API ───────────────────────────────────────────────────────────────

func log_decision(decision: String, cycle_id: int, patient: Node) -> void:
	var decision_time = (Time.get_ticks_msec() / 1000.0) - _cycle_start_time
	var correct := _is_correct(decision, patient)

	_total_cycles += 1
	if not correct:
		mistake_count += 1

	# Subconscious Feedback: Emit for EventManager to schedule LAGGED consequences
	emit_signal("decision_resolved", correct)

	# In Phase 3, we stop printing "CORRECT/WRONG" to hide the system state
	# instead, we log hesitation for future ambient scaling
	if decision_time > 8.0:
		pass # Logic to increase room noise could go here

	var error_rate := float(mistake_count) / float(max(_total_cycles, 1))
	var state := _derive_state(error_rate)

	emit_signal("evaluation_updated", state, cycle_id)


# ─── Internal ─────────────────────────────────────────────────────────────────

func _is_correct(decision: String, patient: Node) -> bool:
	if patient == null:
		return (decision == "no_decision") and not _any_anomalies_present()

	if not patient.has_method("has_visible_anomaly"):
		return false

	var has_anomaly : bool = patient.has_visible_anomaly()
	
	if decision == "Something Wrong":
		return has_anomaly
	if decision == "All Normal":
		return not has_anomaly
		
	return false


func _derive_state(error_rate: float) -> String:
	if error_rate >= fail_threshold: return "failed"
	if error_rate > 0.0: return "unstable"
	return "stable"


func _any_anomalies_present() -> bool:
	var patients = get_tree().get_nodes_in_group("patient")
	for p in patients:
		if p.has_method("has_visible_anomaly") and p.has_visible_anomaly():
			return true
	return false
