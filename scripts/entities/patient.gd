extends CharacterBody3D
## patient.gd
## Responsibility: Target for observation and display of anomaly states.
## Satisfies the display contract for anomaly_manager and evaluation_manager.

@export var patient_name: String = "Patient"
@export var bed_id: int = 0

var _is_anomalous: bool = false
var _current_data: Dictionary = {}

# ─── Lifecycle ────────────────────────────────────────────────────────────────

func _ready() -> void:
	add_to_group("patient")
	collision_layer = 4 # Layer 3 for interaction_system

# ─── Anomaly Contract ─────────────────────────────────────────────────────────

func has_visible_anomaly() -> bool:
	return _is_anomalous


func set_anomaly_state(data: Dictionary) -> void:
	_is_anomalous = true
	_current_data = data
	_update_visuals()


func clear_anomaly() -> void:
	_is_anomalous = false
	_current_data = {}
	_update_visuals()

# ─── Internal Visuals ─────────────────────────────────────────────────────────

func _update_visuals() -> void:
	var mesh = get_node_or_null("MeshInstance3D")
	if not mesh: return

	if not _is_anomalous:
		mesh.rotation_degrees = Vector3.ZERO
		mesh.scale = Vector3(1, 1, 1)
		return

	# Apply anomaly based on variant/intensity
	var variant = _current_data.get("variant", 0)
	var intensity = _current_data.get("intensity", 0.3)

	match variant:
		0: # Posture Distortion
			mesh.rotation_degrees.z = 15.0 * intensity
		1: # Size distortion
			mesh.scale.x = 1.0 + (0.2 * intensity)
		2: # Floating
			mesh.position.y = 0.8 + (0.1 * intensity)
