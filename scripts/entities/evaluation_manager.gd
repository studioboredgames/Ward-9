extends Node
## evaluation_manager.gd
## Responsibility: Score player behavior and emit evaluation state.
## Now includes individual decision resolution for loop feedback.

signal evaluation_updated(state: String, cycle_id: int)
signal decision_resolved(correct: bool) # For immediate player feedback

# ─── Configuration ────────────────────────────────────────────────────────────

@export var suspicious_threshold: float = 0.5
@export var fail_threshold: float = 0.8

# ─── State ────────────────────────────────────────────────────────────────────

var _history: Array = []
var _error_count: int = 0
var _total: int = 0

# ─── Lifecycle ────────────────────────────────────────────────────────────

func _ready() -> void:
	add_to_group("evaluation_manager")

# ─── Public API ───────────────────────────────────────────────────────────────

func log_decision(decision: String, cycle_id: int, patient: Node) -> void:
	var correct := _is_correct(decision, patient)

	# Temporary Feedback Loop (Prints)
	if correct:
		print("Evaluation: [CORRECT] Player identified accurately.")
	else:
		print("Evaluation: [WRONG] Player missed an anomaly or false alarmed.")
	
	# Emit for visual/audio systems to hook into
	emit_signal("decision_resolved", correct)

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
		# Timeout case: correct only if NO anomalies were present in the entire ward
		return (decision == "no_decision") and not _any_anomalies_present()

	if not patient.has_method("has_visible_anomaly"):
		return false

	var has_anomaly : bool = patient.has_visible_anomaly()
	
	# Exact string matching for buttons: "Something Wrong" / "All Normal"
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
