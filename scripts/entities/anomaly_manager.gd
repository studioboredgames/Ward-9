extends Node
## anomaly_manager.gd
## Responsibility: Adaptive anomaly spawning using player behavior profiles.
## Counters player logic by targeting unobserved areas and countering bias.

const ANOMALIES: Array[String] = ["tilt", "breath", "shift"]
var patients: Array[Node] = []
var _current_phase: String = "shift_start"

# ─── Lifecycle ────────────────────────────────────────────────────────────────

func _ready() -> void:
	add_to_group("anomaly_manager")
	call_deferred("_collect_patients")


func _collect_patients() -> void:
	var nodes = get_tree().get_nodes_in_group("patient")
	for n in nodes: patients.append(n)


func handle_phase_shift(phase_name: String) -> void:
	_current_phase = phase_name

# ─── Public API ───────────────────────────────────────────────────────────────

## Called by game_manager router. Receives the learned Behavior Profile.
func prepare_cycle(_cycle_id: int, profile: Dictionary) -> void:
	_clear_all()
	
	if patients.is_empty(): return
	if profile.is_empty(): 
		# Fallback for first cycle or unprofiled starts
		var p = patients.pick_random()
		p.apply_anomaly(ANOMALIES.pick_random())
		return

	# Adaptation Logic Layer
	var target = _select_adaptive_target(profile)
	var anomaly_type = _select_adaptive_anomaly(profile)

	# Anti-Habit Delay: If player is rushing, delay the visual onset
	if profile.get("avg_decision_time", 5.0) < 1.0:
		await get_tree().create_timer(1.0).timeout

	if target and target.has_method("apply_anomaly"):
		target.apply_anomaly(anomaly_type)


func cleanup_cycle(_id: int) -> void:
	pass

# ─── Adaptive Selection ───────────────────────────────────────────────────────

func _select_adaptive_target(profile: Dictionary) -> Node:
	var focus_times: Dictionary = profile.get("focus_time", {})
	var weights := {}
	
	# Weighted Strategy: Focus Punishment
	# Less focus time -> higher spawn probability
	var total_weight = 0.0
	for p in patients:
		var time = focus_times.get(p, 0.0)
		# 1 / max(focus_time, 0.01) creates an inverse weight
		var weight = 1.0 / max(time, 0.01)
		# Reward entropy: if entropy is low (obsessive scanning), increase weights disproportionately
		if profile.get("focus_entropy", 1.0) < 0.5:
			weight *= 2.0
		
		weights[p] = weight
		total_weight += weight

	# Weighted Random Pick
	var roll = randf() * total_weight
	var cursor = 0.0
	for p in weights:
		cursor += weights[p]
		if roll <= cursor:
			return p
	
	return patients.pick_random()


func _select_adaptive_anomaly(profile: Dictionary) -> String:
	var bias = profile.get("bias", {"normal_bias": 0.5})
	
	# Bias Counter: if player over-calls "All Normal", favor more subtle anomalies
	# to force them into careful inspection.
	if bias.get("normal_bias", 0.5) > 0.7:
		return ANOMALIES.pick_random() # In later builds, could return "subtle_tilt" etc.
	
	return ANOMALIES.pick_random()


# ─── Internal ─────────────────────────────────────────────────────────────────

func _clear_all() -> void:
	for p in patients:
		# Unreliable reset late game
		var unreliable = (_current_phase == "pre_dawn") and (randf() < 0.25)
		if p.has_method("clear_anomaly"): p.clear_anomaly(unreliable)
