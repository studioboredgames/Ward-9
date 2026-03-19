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
	_reset_patients()
	_reset_lights()
	
	# Decide which patient (if any) gets an anomaly this cycle
	var target_patient = _select_random_patient()
	if target_patient and randf() < anomaly_chance:
		var anomaly_data = _generate_detectable_anomaly(cycle_id)
		_apply_anomaly(target_patient, anomaly_data)


func cleanup_cycle(_id: int) -> void:
	# Explicit hook for router-driven cleanup if needed
	pass


func _reset_patients() -> void:
	for patient in _patient_nodes:
		patient.set_anomaly_state(false)


func _reset_lights() -> void:
	var lights = get_tree().get_nodes_in_group("bed_light")
	for light in lights:
		if light.has_method("set_flicker_enabled"):
			light.set_flicker_enabled(false)


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
	var anomalies = [
		{"type": "posture", "cue": "unnatural_bend"},
		{"type": "sound", "cue": "whispering"},
		{"type": "flicker", "cue": "light_unstable"}
	]
	
	var selected = anomalies.pick_random()
	selected["cycle_id"] = cycle_id
	return selected


func _apply_anomaly(patient: Node, data: Dictionary) -> void:
	match data.get("type"):
		"flicker":
			# Find the light in the same "PatientUnit" parent
			var parent = patient.get_parent()
			if parent:
				var light = parent.get_node_or_null("BedLight")
				if light and light.has_method("set_flicker_enabled"):
					light.set_flicker_enabled(true)
			# Even for flicker, we mark the patient as "anomalous" 
			# but they might not have a visual mesh shift.
			patient.set_anomaly_state(true, data)
		_:
			patient.set_anomaly_state(true, data)
