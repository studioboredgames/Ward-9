extends Node
## anomaly_manager.gd
## Responsibility: Assign observable anomalies to patients per cycle.
## Patterns: Adaptive Dead Air and Unreliable Fake Anomalies.

const ANOMALIES: Array[String] = ["tilt", "breath", "shift"]
var patients: Array[Node] = []
var _current_phase: String = "shift_start"

# ─── Lifecycle ────────────────────────────────────────────────────────────────

func _ready() -> void:
	add_to_group("anomaly_manager")
	call_deferred("_collect_patients")


func _collect_patients() -> void:
	var nodes = get_tree().get_nodes_in_group("patient")
	for n in nodes:
		patients.append(n)


func handle_phase_shift(phase_name: String) -> void:
	_current_phase = phase_name

# ─── Public API ───────────────────────────────────────────────────────────────

func prepare_cycle(cycle_id: int) -> void:
	_clear_all() # Cleanup previous real ones
	
	if patients.is_empty(): return

	# 1. Dead Air Scaling (Probability of NO anomaly)
	var dead_air_chance = 0.10
	match _current_phase:
		"midnight": dead_air_chance = 0.25
		"pre_dawn": dead_air_chance = 0.40
	
	if randf() < dead_air_chance:
		print("Anomaly Manager: Dead Air. No real anomalies spawned.")
		# Still a chance for "Fake" ones here to induce paranoia
		if randf() < 0.3: _apply_fake_effect()
		return

	# 2. Fake Anomaly Check (20% chance)
	if randf() < 0.20:
		_apply_fake_effect()

	# 3. Real Spawn Distribution
	# Earlier cycles = single, later = chance for double
	if _current_phase == "shift_start" or randf() < 0.7:
		_spawn_single()
	else:
		_spawn_double()


func cleanup_cycle(_cycle_id: int) -> void:
	pass


# ─── Spawning Helpers ─────────────────────────────────────────────────────────

func _spawn_single() -> void:
	var p = patients.pick_random()
	p.apply_anomaly(ANOMALIES.pick_random())


func _spawn_double() -> void:
	var shuffled = patients.duplicate()
	shuffled.shuffle()
	for i in range(min(2, shuffled.size())):
		shuffled[i].apply_anomaly(ANOMALIES.pick_random())


func _apply_fake_effect() -> void:
	var p = patients.pick_random()
	if not p: return
	
	# Fake: brief visual shift that DOES NOT fully reset
	print("Anomaly Manager: Triggering Fake Anomaly on ", p.name)
	
	var tilt = randf_range(3.0, 6.0)
	p.mesh.rotation_degrees.z += tilt
	
	# Delay then PARTIAL reset
	await get_tree().create_timer(randf_range(0.4, 0.8)).timeout
	
	# Only revert 70% of the movement (leave doubt)
	p.mesh.rotation_degrees.z -= (tilt * 0.7)


func _clear_all() -> void:
	for p in patients:
		# Real ones get a clean reset normally, but we can make it unreliable late game
		var unreliable = (_current_phase == "pre_dawn") and (randf() < 0.3)
		p.clear_anomaly(unreliable)
