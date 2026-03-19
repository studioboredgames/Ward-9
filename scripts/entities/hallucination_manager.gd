extends Node
## hallucination_manager.gd
## Responsibility: Manage perceptual corruption and memory desyncs.
## Enforces: Single Distortion Rule, Delayed Causality, and Plausibility Constraints.

# ─── Configuration ────────────────────────────────────────────────────────────

const SILENCE_RATIO = 0.4
const HALLUCINATION_CHANCE = 0.25
const TEMPORAL_ECHO_CHANCE = 0.15
const UI_GLITCH_CHANCE = 0.1
var _ui_lag_active: bool = false

# ─── Private State ────────────────────────────────────────────────────────────

var patients: Array[Node] = []
var _is_distortion_active: bool = false
var _last_outcome: String = "none"
var _anomaly_history: Array = [] # Stores {patient, type}
var _fake_count_this_phase: int = 0
const MAX_FAKE_PER_PHASE := 2

# ─── Lifecycle ────────────────────────────────────────────────────────────────

func _ready() -> void:
	add_to_group("hallucination_manager")
	call_deferred("_collect_patients")


func _collect_patients() -> void:
	var nodes = get_tree().get_nodes_in_group("patient")
	for n in nodes:
		patients.append(n)


# ─── Public API ───────────────────────────────────────────────────────────────

## Called by GameManager at the start of a cycle.
## Receives a profile from 2-3 cycles ago.
func prepare_hallucination(cycle_id: int, profile: Dictionary) -> void:
	if _is_distortion_active: return
	if profile.is_empty(): return
	
	# Rule: Silence Ratio (30-50% must be empty)
	if randf() < SILENCE_RATIO:
		_last_outcome = "none"
		return

	# HARD GATE: Resolve ONE outcome
	var outcome = _resolve_hallucination_outcome(profile)
	_execute_hallucination(outcome)


func cleanup_hallucination() -> void:
	_is_distortion_active = false
	_last_outcome = "none"
	_ui_lag_active = false


func has_ui_lag() -> bool:
	return _ui_lag_active


func cleanup_phase() -> void:
	_fake_count_this_phase = 0


# ─── Internal Logic ───────────────────────────────────────────────────────────

func _resolve_hallucination_outcome(profile: Dictionary) -> Dictionary:
	var accuracy = profile.get("accuracy", 0.0)
	var hesitation = profile.get("avg_decision_time", 0.0)
	
	# Chance scales with confidence (Target high-accuracy players)
	var chance = HALLUCINATION_CHANCE
	if accuracy > 0.7: chance += 0.2
	
	if randf() > chance:
		return {"type": "none"}
	
	# Select type based on behavior
	if randf() < UI_GLITCH_CHANCE:
		return {"type": "ui_betrayal", "patient": null}
		
	var types = ["perception_drift", "memory_desync", "persistence"]
	if randf() < TEMPORAL_ECHO_CHANCE: types.append("temporal_echo")
	if randf() < 0.15: types.append("identity_drift")
	
	# 🧠 Sensory Pressure: Trigger consequences for hesitation
	if hesitation > 4.0:
		_apply_sensory_pressure()
	
	return {
		"type": types.pick_random(),
		"patient": patients.pick_random() if not patients.is_empty() else null
	}


func _execute_hallucination(outcome: Dictionary) -> void:
	if outcome.type == "none" or outcome.patient == null:
		return
	
	_is_distortion_active = true
	_last_outcome = outcome.type
	print("[Hallucination] Triggering: ", outcome.type, " on ", outcome.patient.name)
	
	match outcome.type:
		"perception_drift":
			_apply_perception_drift(outcome.patient)
		"memory_desync":
			_apply_memory_desync(outcome.patient)
		"persistence":
			_apply_fake_persistence(outcome.patient)
		"temporal_echo":
			_apply_temporal_echo(outcome.patient)
		"ui_betrayal":
			_apply_ui_betrayal()
		"identity_drift":
			_apply_identity_drift(outcome.patient)


# ─── Specific Effects ─────────────────────────────────────────────────────────

func _apply_perception_drift(patient: Node) -> void:
	# Subtle transform change that is NOT an anomaly
	if not patient.has_method("get"): return
	var mesh = patient.get("mesh")
	if not mesh: return
	
	# Plausibility Constraint: Barely noticeable
	var type = ["tilt", "shift"].pick_random()
	match type:
		"tilt":
			mesh.rotation_degrees.z += randf_range(1.5, 3.0)
		"shift":
			mesh.position.x += randf_range(0.01, 0.02)


func _apply_memory_desync(patient: Node) -> void:
	# Revert/change after looking away
	# Logic: Wait for patient to NOT be focused, then restore history
	if not patient.has_method("restore_previous_state"): return
	
	# Delay: 1.0 - 2.5s
	var delay = randf_range(1.0, 2.5)
	await get_tree().create_timer(delay).timeout
	
	# Plausibility: Only if player isn't staring
	if patient.get("is_player_focusing") == false:
		patient.restore_previous_state()


func register_real_anomaly(patient: Node, type: String) -> void:
	# Delayed Causality: Store real anomalies for temporal echoes
	if not _anomaly_history.has({"patient": patient, "type": type}):
		_anomaly_history.append({"patient": patient, "type": type})
		if _anomaly_history.size() > 5: _anomaly_history.pop_front()


func _apply_fake_persistence(patient: Node) -> void:
	# Fake anomaly lingers after "Cleanup"
	if _fake_count_this_phase >= MAX_FAKE_PER_PHASE: return
	_fake_count_this_phase += 1
	
	if patient.has_method("apply_anomaly"):
		patient.apply_anomaly("tilt") 
		if patient.has_method("set_lingering"):
			patient.set_lingering(true)
		print("[Hallucination] Persistence: Fake anomaly will linger on ", patient.name)


func _apply_temporal_echo(patient: Node) -> void:
	# Replay a previous anomaly
	if _anomaly_history.is_empty(): return
	var old = _anomaly_history.pick_random()
	if patient.has_method("apply_anomaly"):
		print("[Hallucination] Temporal Echo: Replaying ", old.type, " on ", patient.name)
		patient.apply_anomaly(old.type)


func _apply_ui_betrayal() -> void:
	# UI Flickers or input lag
	var ui = get_tree().get_first_node_in_group("decision_ui")
	if not ui: return
	
	print("[Hallucination] UI Betrayal: Injecting perceptual lag")
	if randf() < 0.5:
		# Visible flicker
		ui.modulate.a = 0.5
		await get_tree().create_timer(0.1).timeout
		ui.modulate.a = 1.0
	else:
		_ui_lag_active = true


func _apply_identity_drift(patient: Node) -> void:
	# Subtly shift baseline position permanently (barely noticeable)
	if not patient.has_method("get"): return
	var mesh = patient.get("mesh")
	if not mesh: return
	
	print("[Hallucination] Identity Drift: Shifting baseline for ", patient.name)
	mesh.position.y += randf_range(-0.005, 0.005)


func _apply_sensory_pressure() -> void:
	# Distant sounds or lighting pulses
	var events = get_tree().get_first_node_in_group("event_manager")
	if events and events.has_method("_trigger_environmental_event"):
		print("[Hallucination] Sensory Pressure: Triggering atmospheric event")
		events.call_deferred("_trigger_environmental_event")
