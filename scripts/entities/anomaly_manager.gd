extends Node
## anomaly_manager.gd
## Responsibility: Adaptive anomaly spawning using player behavior profiles.
## Counters player logic by targeting unobserved areas and countering bias.

const ANOMALIES: Array[String] = ["tilt", "breath", "shift"]
var patients: Array[Node] = []
var _current_phase: String = "shift_start"
var _last_cycle_processed: int = -1

var _last_target: Node = null
var _target_cooldown: Dictionary = {} # Node -> float penalty

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
func prepare_cycle(cycle_id: int, profile: Dictionary) -> void:
	if cycle_id == _last_cycle_processed: return
	_last_cycle_processed = cycle_id
	
	_clear_all()
	_decay_cooldowns()
	
	if patients.is_empty(): return
	if profile.is_empty(): 
		# Fallback for first cycle or unprofiled starts
		var p = patients.pick_random()
		p.apply_anomaly(ANOMALIES.pick_random())
		return

	# Adaptation Logic Layer
	var target = _select_adaptive_target(profile)
	var anomaly_type = _select_adaptive_anomaly(profile)

	# Entropy Usage: High scanning entropy -> player is careful -> increase fakes
	if profile.get("focus_entropy", 0.0) > 1.0:
		if randf() < 0.4:
			_apply_fake_effect()

	# Anti-Habit Delay: If player is rushing, delay the visual onset
	if profile.get("avg_decision_time", 5.0) < 1.0:
		await get_tree().create_timer(1.0).timeout

	if target and target.has_method("apply_anomaly"):
		print("[AnomalyManager] Triggering Adaptive Anomaly: ", anomaly_type, " on ", target.name)
		target.apply_anomaly(anomaly_type)


func cleanup_cycle(_id: int) -> void:
	pass

# ─── Adaptive Selection ───────────────────────────────────────────────────────

func _select_adaptive_target(profile: Dictionary) -> Node:
	var weights = _build_weights(profile)
	
	# Apply Cooldown Penalties to filtered list
	var filtered := {}
	var total_weight := 0.0
	
	for p in weights.keys():
		var penalty = _target_cooldown.get(p, 0.0)
		# Reduce weight by penalty percentage
		filtered[p] = weights[p] * (1.0 - penalty)
		total_weight += filtered[p]

	# Weighted Random Pick
	var roll = randf() * total_weight
	var cursor = 0.0
	for p in filtered:
		cursor += filtered[p]
		if roll <= cursor:
			_apply_target_cooldown(p)
			return p
	
	return patients.pick_random()


func _build_weights(profile: Dictionary) -> Dictionary:
	var weights := {}
	var focus_times = profile.get("focus_time", {})
	
	var max_time = 0.01
	for t in focus_times.values():
		max_time = max(max_time, t)
	
	for p in patients:
		var t = focus_times.get(p, 0.0)
		var normalized = t / max_time
		
		# Stable Bounded Range: 1.5 (unobserved) to 0.5 (watched)
		weights[p] = lerp(1.5, 0.5, normalized)
		
	return weights


func _apply_target_cooldown(target: Node) -> void:
	_last_target = target
	_target_cooldown[target] = 0.7 # Heavy 70% weight penalty next cycle


func _decay_cooldowns() -> void:
	for p in _target_cooldown.keys():
		_target_cooldown[p] = max(0.0, _target_cooldown[p] - 0.4) # Decays over ~2 cycles


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


func _apply_fake_effect() -> void:
	if patients.is_empty(): return
	var p = patients.pick_random()
	if p.has_method("apply_anomaly"):
		print("[AnomalyManager] Entropy Payload: Triggering Fake Anomaly on ", p.name)
		p.apply_anomaly("tilt") # Temporary visual
		await get_tree().create_timer(0.4).timeout
		if p.has_method("clear_anomaly"):
			p.clear_anomaly(true) # Always unreliable for fake
