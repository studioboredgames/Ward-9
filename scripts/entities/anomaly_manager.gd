extends Node
## anomaly_manager.gd
## Responsibility: Global authority on selecting and applying anomalies.
## Ensures all anomalies are player-detectable via visible/audible cues.
## Patients are display-only; this manager tells them what to show.

# ─── Configuration ────────────────────────────────────────────────────────────

@export var anomaly_chance: float = 0.5  ## Probability of a patient being anomalous

# ─── Private State ────────────────────────────────────────────────────────────

var _patient_nodes: Array[Node] = []

# ─── Lifecycle ────────────────────────────────────────────────────────────────

func _ready() -> void:
	add_to_group("anomaly_manager")
	# Defer finding patients to ensure they are in the tree
	call_deferred("_find_patients")

# ─── Public API ───────────────────────────────────────────────────────────────

## Called by game_manager at cycle_start.
func prepare_cycle(cycle_id: int) -> void:
	# Clear all patients first
	for patient in _patient_nodes:
		patient.set_anomaly_state(false)
	
	# Decide which patient (if any) gets an anomaly this cycle
	# In early phases, maybe only 1. In late phases, maybe more.
	var target_patient = _select_random_patient()
	if target_patient and randf() < anomaly_chance:
		var anomaly_data = _generate_detectable_anomaly(cycle_id)
		target_patient.set_anomaly_state(true, anomaly_data)


func handle_phase_shift(phase_name: String) -> void:
	# Adjust anomaly types or frequency based on phase
	match phase_name:
		"midnight":
			anomaly_chance = 0.6
		"pre_dawn":
			anomaly_chance = 0.8

# ─── Internal ─────────────────────────────────────────────────────────────────

func _find_patients() -> void:
	_patient_nodes = get_tree().get_nodes_in_group("patient")


func _select_random_patient() -> Node:
	if _patient_nodes.is_empty():
		return null
	return _patient_nodes.pick_random()


func _generate_detectable_anomaly(cycle_id: int) -> Dictionary:
	# Define a set of detectable anomalies
	# Every anomaly MUST have a player-observable cue (visual/audio)
	var anomalies = [
		{"type": "posture", "cue": "unnatural_bend", "intensity": 1.0},
		{"type": "sound", "cue": "whispering", "volume": -10.0},
		{"type": "visual", "cue": "eye_color_shift", "color": Color.RED},
		{"type": "behavior", "cue": "rhythmic_tapping", "speed": 2.0}
	]
	
	var selected = anomalies.pick_random()
	selected["cycle_id"] = cycle_id
	return selected
