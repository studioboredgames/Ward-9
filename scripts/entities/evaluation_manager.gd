extends Node
## evaluation_manager.gd
## Responsibility: Score player behavior and emit evaluation state.
## Deterministic, history-aware scoring system.

signal evaluation_updated(state: String, cycle_id: int)

# ─── Configuration ────────────────────────────────────────────────────────────

@export var suspicious_threshold: float = 0.5 ## Error rate to trigger suspicion
@export var fail_threshold: float = 0.8       ## Error rate for shift failure

# ─── State ────────────────────────────────────────────────────────────────────

var _history: Array = []  # [{cycle_id, correct: bool, patient: Node, decision: String}]
var _error_count: int = 0
var _total: int = 0

# ─── Public API ───────────────────────────────────────────────────────────────

func log_decision(decision: String, cycle_id: int, patient: Node) -> void:
	var correct := _is_correct(decision, patient)

	_total += 1
	if not correct:
		_error_count += 1

	_history.append({
		"cycle_id": cycle_id,
		"correct": correct,
		"patient": patient,
		"decision": decision
	})

	var error_rate := float(_error_count) / float(max(_total, 1))
	var state := _derive_state(error_rate)

	emit_signal("evaluation_updated", state, cycle_id)

# ─── Internal ─────────────────────────────────────────────────────────────────

func _is_correct(decision: String, patient: Node) -> bool:
	if patient == null:
		# treat no target (timeout) as incorrect if an anomaly was present
		var has_any := _any_anomalies_present()
		return (decision == "all_normal" or decision == "no_decision") and not has_any

	# Target patient must expose the visible anomaly flag
	if not patient.has_method("has_visible_anomaly"):
		return false

	var has_anomaly : bool = patient.has_visible_anomaly()
	
	if decision == "Something Wrong":
		return has_anomaly
	if decision == "All Normal":
		return not has_anomaly
		
	return false

func _derive_state(error_rate: float) -> String:
	if error_rate >= fail_threshold:
		return "failed"
	elif error_rate >= suspicious_threshold:
		return "suspicious"
	return "stable"

func _any_anomalies_present() -> bool:
	var patients = get_tree().get_nodes_in_group("patient")
	for p in patients:
		if p.has_method("has_visible_anomaly") and p.has_visible_anomaly():
			return true
	return false
