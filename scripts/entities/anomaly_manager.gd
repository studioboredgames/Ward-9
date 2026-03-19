extends Node
## anomaly_manager.gd
## Responsibility: Assign observable anomalies to patients per cycle.
## Minimal version: 70% chance of 1 random anomaly.

const ANOMALIES: Array[String] = ["tilt", "breath", "shift"]
var patients: Array[Node] = []

# ─── Lifecycle ────────────────────────────────────────────────────────────────

func _ready() -> void:
	add_to_group("anomaly_manager")
	# Collect patients on startup
	call_deferred("_collect_patients")


func _collect_patients() -> void:
	var nodes = get_tree().get_nodes_in_group("patient")
	for n in nodes:
		patients.append(n)

# ─── Public API ───────────────────────────────────────────────────────────────

## Called by game_manager router at start of cycle.
func prepare_cycle(_cycle_id: int) -> void:
	_clear_all()

	# 70% chance of anomaly per cycle
	if randf() < 0.7 and not patients.is_empty():
		var target_patient = patients.pick_random()
		var anomaly_type = ANOMALIES.pick_random()

		if target_patient.has_method("apply_anomaly"):
			target_patient.apply_anomaly(anomaly_type)


func cleanup_cycle(_cycle_id: int) -> void:
	# Optional hook, could be used for phase-down transients
	pass


func handle_phase_shift(_phase_name: String) -> void:
	# Hook for future scaling
	pass


# ─── Internal ─────────────────────────────────────────────────────────────────

func _clear_all() -> void:
	for p in patients:
		if p.has_method("clear_anomaly"):
			p.clear_anomaly()
