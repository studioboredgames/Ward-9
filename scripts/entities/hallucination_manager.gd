extends Node
## hallucination_manager.gd
## Responsibility: Manage perceptual corruption and memory desyncs.
## Enforces: Single Distortion Rule, Delayed Causality, and Plausibility Constraints.

# ─── Configuration ────────────────────────────────────────────────────────────

const SILENCE_RATIO = 0.4
const HALLUCINATION_CHANCE = 0.25
const TEMPORAL_ECHO_CHANCE = 0.15

# ─── Private State ────────────────────────────────────────────────────────────

var patients: Array[Node] = []
var _is_distortion_active: bool = false
var _last_outcome: String = "none"

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
	var types = ["perception_drift", "memory_desync", "persistence"]
	if randf() < TEMPORAL_ECHO_CHANCE: types.append("temporal_echo")
	
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


func _apply_fake_persistence(patient: Node) -> void:
	# TODO: Implement persistence logic (requires interaction with clear_anomaly)
	pass


func _apply_temporal_echo(patient: Node) -> void:
	# TODO: Implement temporal echo (requires anomaly history)
	pass
