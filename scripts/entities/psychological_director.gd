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
var consequence_queue: Array = [] # Stores {type, cycle_target}

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
	_check_consequence_queue()
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
	
	# Phase 7: Delayed Consequences (Queue a follow-up)
	if result.get("queued_effect"):
		consequence_queue.append({
			"type": result.queued_effect,
			"target_cycle": current_cycle + randi_range(2, 3)
		})


func _check_consequence_queue() -> void:
	for i in range(consequence_queue.size() - 1, -1, -1):
		var c = consequence_queue[i]
		if current_cycle >= c.target_cycle:
			_execute_consequence(c)
			consequence_queue.remove_at(i)


func _execute_consequence(c: Dictionary) -> void:
	print("[Director] Executing Delayed Consequence: ", c.type)
	if c.type == "truth_flip":
		var ti = get_tree().get_first_node_in_group("truth_instability")
		if ti: ti.set_deferred("active_this_cycle", true)


# ─── Strategy Selection ───────────────────────────────────────────────────────

func _select_distortion(profile: Dictionary) -> Dictionary:
	var entropy = profile.get("focus_entropy", 1.0)
	var bias = profile.get("bias", {"normal_bias": 0.5})
	var speed = profile.get("avg_decision_time", 5.0)
	var _accuracy = profile.get("accuracy", 1.0)
	
	var type = "perception_drift"
	var target = _random_patient()
	var queued = null

	# Phase 9 & 10: Control & Identity Attacks
	if speed < 3.0: # Fast Player: Trap with persistence
		type = "fake_persistence"
		if randf() < 0.3: queued = "truth_flip" # Punish speed later
	elif entropy < 0.6: # Paranoia: Target blindness
		type = "temporal_echo"
	elif bias.get("normal_bias", 0.0) > 0.8: # Passive: Bleed
		type = "reality_bleed" # Maps to distorter
	else:
		var pool = ["perception_drift", "memory_desync", "ui_betrayal"]
		type = pool.pick_random()

	return {
		"type": type,
		"payload": {
			"target": target,
			"type": "tilt",
			"speed_context": speed
		},
		"queued_effect": queued
	}


func _random_patient() -> Node:
	if patients.is_empty(): return null
	return patients.pick_random()
