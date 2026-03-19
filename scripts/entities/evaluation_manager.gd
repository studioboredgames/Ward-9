extends Node
## evaluation_manager.gd
## Responsibility: Profile player behavior (entropy, bias, decision speed).
## Emits behavioral profiles to drive adaptive system strategies.

signal behavior_profile_updated(profile: Dictionary)
signal evaluation_updated(state: String, cycle_id: int)
signal decision_resolved(correct: bool) 

# ─── Configuration ────────────────────────────────────────────────────────────

@export var fail_threshold: float = 0.8

# ─── Raw Data ─────────────────────────────────────────────────────────────────

var decision_times: Array[float] = []
var focus_time_per_patient: Dictionary = {}
var total_focus_time: float = 0.0

var anomaly_guesses: int = 0
var normal_guesses: int = 0
var mistake_count: int = 0
var total_cycles: int = 0

# ─── Private State ────────────────────────────────────────────────────────────

var _cycle_start_time: float = 0.0

# ─── Lifecycle ────────────────────────────────────────────────────────────────

func _ready() -> void:
	add_to_group("evaluation_manager")


func reset_cycle_timer() -> void:
	_cycle_start_time = Time.get_ticks_msec() / 1000.0


# ─── Focus Tracking API ───────────────────────────────────────────────────────

func on_focus_started(patient: Node) -> void:
	if not focus_time_per_patient.has(patient):
		print("[Interaction] Focus Started: ", patient.name)
		patient.set_meta("focus_start_time", Time.get_ticks_msec())


func on_focus_ended(patient: Node) -> void:
	if not patient.has_meta("focus_start_time"):
		return
	
	var start = patient.get_meta("focus_start_time")
	var duration = (Time.get_ticks_msec() - start) / 1000.0
	
	focus_time_per_patient[patient] += duration
	total_focus_time += duration
	print("[Interaction] Focus Ended: ", patient.name, " duration: ", duration, "s | Total: ", focus_time_per_patient[patient])
	patient.remove_meta("focus_start_time")

# ─── Profiling Logic ──────────────────────────────────────────────────────────

func log_decision(decision: String, cycle_id: int, patient: Node) -> void:
	var decision_time = (Time.get_ticks_msec() / 1000.0) - _cycle_start_time
	decision_times.append(decision_time)
	
	var correct := _is_correct(decision, patient)
	
	total_cycles += 1
	if not correct: mistake_count += 1
	
	if decision == "Something Wrong": anomaly_guesses += 1
	else: normal_guesses += 1

	emit_signal("decision_resolved", correct)
	
	var profile = _build_profile()
	print("[Evaluation] Profile Updated: ", profile)
	emit_signal("behavior_profile_updated", profile)

	var error_rate := float(mistake_count) / float(max(total_cycles, 1))
	emit_signal("evaluation_updated", _derive_state(error_rate), cycle_id)


func _build_profile() -> Dictionary:
	return {
		"avg_decision_time": _avg(decision_times),
		"focus_entropy": _calculate_focus_entropy(),
		"bias": _calculate_bias(),
		"accuracy": float(total_cycles - mistake_count) / float(max(total_cycles, 1)),
		"focus_time": focus_time_per_patient.duplicate()
	}


func _calculate_focus_entropy() -> float:
	if total_focus_time == 0: return 0.0
	var entropy := 0.0
	for p_time in focus_time_per_patient.values():
		var prob = p_time / total_focus_time
		if prob > 0: entropy -= prob * log(prob)
	return entropy


func _calculate_bias() -> Dictionary:
	var total = anomaly_guesses + normal_guesses
	if total == 0: return {"anomaly_bias": 0.5, "normal_bias": 0.5}
	return {
		"anomaly_bias": float(anomaly_guesses) / float(total),
		"normal_bias": float(normal_guesses) / float(total)
	}

# ─── Internal ─────────────────────────────────────────────────────────────────

func _is_correct(decision: String, patient: Node) -> bool:
	if patient == null:
		return (decision == "no_decision") and not _any_anomalies_present()
	if not patient.has_method("has_visible_anomaly"): return false
	
	var has_anomaly : bool = patient.has_visible_anomaly()
	if decision == "Something Wrong": return has_anomaly
	if decision == "All Normal": return not has_anomaly
	return false


func _derive_state(error_rate: float) -> String:
	if error_rate >= fail_threshold: return "failed"
	if error_rate > 0.0: return "unstable"
	return "stable"


func _any_anomalies_present() -> bool:
	var patients = get_tree().get_nodes_in_group("patient")
	for p in patients:
		if p.has_method("has_visible_anomaly") and p.has_visible_anomaly(): return true
	return false


func _avg(arr: Array) -> float:
	if arr.is_empty(): return 0.0
	var sum = 0.0
	for v in arr: sum += v
	return sum / arr.size()
