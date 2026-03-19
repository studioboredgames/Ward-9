extends Node
## hallucination_manager.gd (Refactored Phase 5)
## Responsibility: Passive executioner for distortons requested by the Director.

var active: bool = false

func _ready() -> void:
	add_to_group("hallucination_manager")

func trigger(type: String, payload: Dictionary) -> void:
	if active: return
	
	active = true
	print("[Hallucination] Executing: ", type, " on ", payload.get("target").name if payload.get("target") else "UI")
	
	match type:
		"perception_drift":
			_apply_perception_drift(payload)
		"memory_desync":
			_apply_memory_desync(payload)
		"fake_persistence":
			_apply_fake_persistence(payload)
		"temporal_echo":
			_apply_temporal_echo(payload)
	
	# Reset guard after a short window
	await get_tree().create_timer(2.0).timeout
	active = false


# ─── Realizations ─────────────────────────────────────────────────────────────

func _apply_perception_drift(p: Dictionary) -> void:
	var patient = p.get("target")
	if not patient: return
	var mesh = patient.get("mesh")
	if not mesh: return
	
	mesh.rotation_degrees.z += randf_range(2.0, 5.0)


func _apply_memory_desync(p: Dictionary) -> void:
	await get_tree().create_timer(randf_range(1.0, 2.0)).timeout
	
	if p.get("target") and p.get("target").has_method("clear_anomaly"):
		p.get("target").clear_anomaly()


func _apply_fake_persistence(p: Dictionary) -> void:
	var patient = p.get("target")
	if not patient: return
	
	patient.apply_anomaly(p.get("type", "tilt"))
	await get_tree().create_timer(2.5).timeout
	if patient.has_method("clear_anomaly"):
		patient.clear_anomaly()


func _apply_temporal_echo(p: Dictionary) -> void:
	await get_tree().create_timer(0.8).timeout
	if p.get("target") and p.get("target").has_method("apply_anomaly"):
		p.get("target").apply_anomaly(p.get("type", "tilt"))
