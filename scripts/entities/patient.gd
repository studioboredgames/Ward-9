extends CharacterBody3D
## patient.gd
## Responsibility: Target for observation and display of anomaly states.
## Display-only: does NOT decide anomalies or handle game state.
## Assigned to group "patient" for detection by interaction_system.

# ─── Configuration ────────────────────────────────────────────────────────────

@export var patient_name: String = "Patient"
@export var bed_id: int = 0

# ─── Private State ────────────────────────────────────────────────────────────

var _is_anomalous: bool = false
var _current_anomaly_data: Dictionary = {}

# ─── Lifecycle ────────────────────────────────────────────────────────────────

func _ready() -> void:
	add_to_group("patient")
	# Ensure collision layer is correctly set for interaction_system (Layer 3)
	collision_layer = 0b100 # Bit 3 (value 4)
	collision_mask = 1 # Environment typically


func _physics_process(_delta: float) -> void:
	# Passive animations or look-at logic could go here
	pass

# ─── Public API (called by anomaly_manager) ───────────────────────────────────

## Receives state from global anomaly_manager.
## anomaly_data contains visual/audio triggers.
func set_anomaly_state(anomalous: bool, anomaly_data: Dictionary = {}) -> void:
	_is_anomalous = anomalous
	_current_anomaly_data = anomaly_data
	
	if _is_anomalous:
		_apply_anomaly_effects()
	else:
		_clear_anomaly_effects()


func _apply_anomaly_effects() -> void:
	# 1. Posture Distortion (Subtle rotation shift)
	if _current_anomaly_data.get("type") == "posture":
		# Rotate the mesh in an unnatural way
		var mesh = get_node_or_null("MeshInstance3D")
		if mesh:
			mesh.rotation_degrees.z = 15.0 # Unnatural tilt
			mesh.rotation_degrees.x = -5.0
	
	# 2. Sound Anomaly
	if _current_anomaly_data.get("type") == "sound":
		# Play whisper loop on child AudioStreamPlayer3D
		var audio = get_node_or_null("AudioStreamPlayer3D")
		if audio:
			audio.play()


func _clear_anomaly_effects() -> void:
	# Reset visuals
	var mesh = get_node_or_null("MeshInstance3D")
	if mesh:
		mesh.rotation_degrees = Vector3.ZERO
	
	# Stop audio
	var audio = get_node_or_null("AudioStreamPlayer3D")
	if audio:
		audio.stop()

# ─── Query API ───────────────────────────────────────────────────────────────

func is_anomalous() -> bool:
	return _is_anomalous
