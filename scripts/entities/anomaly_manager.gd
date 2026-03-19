extends Node
## anomaly_manager.gd
## Responsibility: Assign observable anomalies to patients per cycle.
## Pattern-breaking version: Variable spawn counts (None, Single, Double).

const ANOMALIES: Array[String] = ["tilt", "breath", "shift"]
var patients: Array[Node] = []

# ─── Lifecycle ────────────────────────────────────────────────────────────────

func _ready() -> void:
	add_to_group("anomaly_manager")
	call_deferred("_collect_patients")


func _collect_patients() -> void:
	var nodes = get_tree().get_nodes_in_group("patient")
	for n in nodes:
		patients.append(n)

# ─── Public API ───────────────────────────────────────────────────────────────

func prepare_cycle(_cycle_id: int) -> void:
	_clear_all()
	
	if patients.is_empty(): return

	# Pattern-Breaker Logic: Induced Uncertainty
	var roll = randf()
	
	if roll < 0.60:
		_spawn_single()
	elif roll < 0.85:
		_spawn_none()
	else:
		_spawn_double()


func cleanup_cycle(_cycle_id: int) -> void:
	pass


# ─── Internal Spawning Helpers ───────────────────────────────────────────────

func _spawn_none() -> void:
	# Intentional false negative/safe cycle
	print("Anomaly Manager: No anomalies spawned this cycle.")


func _spawn_single() -> void:
	var p = patients.pick_random()
	var anomaly = ANOMALIES.pick_random()
	if p.has_method("apply_anomaly"):
		p.apply_anomaly(anomaly)
	print("Anomaly Manager: Single anomaly spawned.")


func _spawn_double() -> void:
	var shuffled = patients.duplicate()
	shuffled.shuffle()
	
	# Attempt to spawn 2, but respect patient count
	var count = min(2, shuffled.size())
	for i in range(count):
		var anomaly = ANOMALIES.pick_random()
		if shuffled[i].has_method("apply_anomaly"):
			shuffled[i].apply_anomaly(anomaly)
	
	print("Anomaly Manager: Double anomaly spawned.")


func _clear_all() -> void:
	for p in patients:
		if p.has_method("clear_anomaly"):
			p.clear_anomaly()
