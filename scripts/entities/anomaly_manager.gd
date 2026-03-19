extends Node
## anomaly_manager.gd
## Responsibility: Adaptive anomaly spawning using player behavior profiles.
## Counters player logic by targeting unobserved areas and countering bias.

const ANOMALIES: Array[String] = ["tilt", "breath", "shift"]
var patients: Array[Node] = []
var _current_phase: String = "shift_start"
var _last_cycle_processed: int = -1
var _anomaly_fired_this_cycle: bool = false # HARD execution guard

var _last_target: Node = null
signal anomaly_spawned(patient: Node, type: String)
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
	_anomaly_fired_this_cycle = false # Reset at start of new attempt
	_decay_cooldowns()
	
	if patients.is_empty(): return
	
	_run_adaptive_cycle(profile)


func _run_adaptive_cycle(profile: Dictionary) -> void:
	if _anomaly_fired_this_cycle: return
	
	# 🧠 Problem 2: Punish Passivity (Normal Bias)
	var bias = profile.get("bias", {"normal_bias": 0.5})
	var force_real = false
	if bias.get("normal_bias", 0.0) > 0.8:
		force_real = true
		print("[AnomalyManager] Passivity detected. Forcing real anomaly.")

	# 🧠 Memory Violation Trigger (15% chance)
	if not force_real and randf() < 0.15:
		var p = patients.pick_random()
		if p.has_method("restore_previous_state"):
			_anomaly_fired_this_cycle = true
			p.restore_previous_state()
			return

	if profile.is_empty(): 
		# Fallback for first cycle
		var p = patients.pick_random()
		p.apply_anomaly(ANOMALIES.pick_random())
		return

	# Adaptation Logic Layer
	var target = _select_adaptive_target(profile)
	var anomaly_type = _select_adaptive_anomaly(profile)

	# 🧠 Confidence Trap: Reward high accuracy with more subtlety
	var accuracy = profile.get("accuracy", 0.0)
	var detail_multiplier = 1.0
	var fake_boost = 0.0
	
	if accuracy > 0.7:
		detail_multiplier = 0.5 # Shrink anomaly visuals
		fake_boost = 0.2
	
	# Entropy Usage: Smooth scaling fake chance
	var entropy = profile.get("focus_entropy", 0.0)
	var fake_chance = clamp((entropy - 0.7) * 0.8, 0.0, 0.4) + fake_boost
	
	if not force_real and randf() < fake_chance:
		_apply_fake_effect()
		return

	# 🧠 Confidence Collapse Trigger: Punish Hesitation
	var avg_time = profile.get("avg_decision_time", 5.0)
	if avg_time > 5.0:
		print("[AnomalyManager] Hesitation detected. Triggering Confidence Collapse.")
		_apply_fake_effect() # Punish waiting with a trick
		return

	# 🧠 Late-Cycle Injection: Delay anomaly to create pressure
	var phase_manager = get_tree().get_first_node_in_group("phase_manager")
	if phase_manager:
		var time_remaining = phase_manager.get_time_remaining()
		# If early in cycle (more than 5s left), 40% chance to skip/delay
		# force_real bypasses the delay
		if not force_real and time_remaining > 5.0 and randf() < 0.4:
			print("[AnomalyManager] Delaying anomaly injection for tension.")
			return 

	if target and target.has_method("apply_anomaly"):
		if _anomaly_fired_this_cycle: return
		_anomaly_fired_this_cycle = true
		print("[AnomalyManager] Triggering Adaptive Anomaly: ", anomaly_type, " on ", target.name, " (Intensity: ", detail_multiplier, ")")
		target.apply_anomaly(anomaly_type, detail_multiplier)
		emit_signal("anomaly_spawned", target, anomaly_type)
		
		# Record for Paranoia Analysis
		var analyzer = get_tree().get_first_node_in_group("behavior_analyzer")
		if analyzer: analyzer.record_focus(target)


func cleanup_cycle(_id: int) -> void:
	_anomaly_fired_this_cycle = false

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

	# Paranoia Logic (Phase 6): target least observed if entropy is low
	var analyzer = get_tree().get_first_node_in_group("behavior_analyzer")
	if analyzer and profile.get("focus_entropy", 1.0) < 0.6:
		var least = analyzer.get_least_observed(patients)
		if least:
			_apply_target_cooldown(least)
			return least

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


# ─── Clinical Betrayal (Reactive Changes) ────────────────────────────────────

func _on_focus_ended(patient: Node, duration: float) -> void:
	if _anomaly_fired_this_cycle: return
	
	# 🧠 Problem 3: Focus Betrayal Upgrade (Reality Instability)
	if duration > 3.0:
		_anomaly_fired_this_cycle = true
		if randf() < 0.5:
			print("[AnomalyManager] Focus Betrayal (Strong): Memory Violation on ", patient.name)
			patient.restore_previous_state()
		else:
			print("[AnomalyManager] Focus Betrayal (Weak): Micro-change on ", patient.name)
			_trigger_micro_change(patient)


func _trigger_micro_change(patient: Node) -> void:
	if not patient or not patient.has_method("apply_anomaly"):
		return
	
	var type = ["tilt", "shift"].pick_random()
	var mesh = patient.get("mesh")
	if not mesh: return
	
	# Ultra-subtle visual nudge (NOT a full anomaly state)
	match type:
		"tilt":
			mesh.rotation_degrees.z += randf_range(2.0, 5.0)
		"shift":
			mesh.position.x += randf_range(0.01, 0.03)


# ─── Internal ─────────────────────────────────────────────────────────────────

func _clear_all() -> void:
	for p in patients:
		# Unreliable reset late game
		var unreliable = (_current_phase == "pre_dawn") and (randf() < 0.25)
		if p.has_method("clear_anomaly"): p.clear_anomaly(unreliable)


func _apply_fake_effect() -> void:
	if _anomaly_fired_this_cycle: return
	_anomaly_fired_this_cycle = true
	
	if patients.is_empty(): return
	var p = patients.pick_random()
	if p.has_method("apply_anomaly"):
		print("[AnomalyManager] Entropy Payload: Triggering Fake Anomaly on ", p.name)
		p.apply_anomaly("tilt") # Temporary visual
		await get_tree().create_timer(0.4).timeout
		if p.has_method("clear_anomaly"):
			p.clear_anomaly(true) # Always unreliable for fake
