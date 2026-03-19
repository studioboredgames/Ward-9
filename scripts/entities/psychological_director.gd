extends Node
## psychological_director.gd
## Responsibility: Global orchestration of psychological systems (Phases 5–10)
## Enforces delay, silence, and single-distortion rules.

signal distortion_requested(type: String, payload: Dictionary)

# ─── Configuration ────────────────────────────────────────────────────────────

const HISTORY_SIZE := 3
const SILENCE_CHANCE := 0.4

# ─── Private State ────────────────────────────────────────────────────────────

var profile_history: Array = []
var distortion_active: bool = false
var current_cycle: int = 0
var patients: Array[Node] = []

# ─── Lifecycle ────────────────────────────────────────────────────────────────

func _ready() -> void:
	add_to_group("psychological_director")
	call_deferred("_collect_patients")


func _collect_patients() -> void:
	patients = get_tree().get_nodes_in_group("patient")


# ─── Public API (Routing) ─────────────────────────────────────────────────────

func register_cycle(cycle_id: int) -> void:
	current_cycle = cycle_id
	distortion_active = false
	print("[Director] New Cycle Registered: ", cycle_id)


func update_profile(profile: Dictionary) -> void:
	profile_history.append(profile.duplicate())
	if profile_history.size() > HISTORY_SIZE:
		profile_history.pop_front()


func process_cycle() -> void:
	if distortion_active:
		return
	
	if profile_history.size() < HISTORY_SIZE:
		return
	
	# Rule: Silence Ratio
	if randf() < SILENCE_CHANCE:
		print("[Director] Decision: Silence.")
		return
	
	# Delayed Causality: Use the oldest profile in history
	var profile = profile_history[0] 
	
	var result = _select_distortion(profile)
	
	if result.is_empty():
		return
	
	distortion_active = true
	print("[Director] Orchestrating Distortion: ", result.type)
	emit_signal("distortion_requested", result.type, result.payload)


# ─── Strategy Selection ───────────────────────────────────────────────────────

func _select_distortion(profile: Dictionary) -> Dictionary:
	# Select distortion based on behavior profile
	var type = "perception_drift"
	var target = _random_patient()
	
	# Phase 9: Identity Attack (Speed Punishment)
	if profile.get("avg_decision_time", 5.0) < 2.5:
		type = "fake_persistence"
	elif profile.get("accuracy", 1.0) > 0.8:
		type = "memory_desync"
	else:
		var types = ["perception_drift", "temporal_echo"]
		type = types.pick_random()

	return {
		"type": type,
		"payload": {
			"target": target,
			"type": "tilt" # Default type for persistence/echoes if not stored
		}
	}


func _random_patient() -> Node:
	if patients.is_empty(): return null
	return patients.pick_random()
