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
	# Logic to change model, visibility, or play sounds
	# Example: $AnimationPlayer.play(_current_anomaly_data.get("anim", "idle"))
	pass


func _clear_anomaly_effects() -> void:
	# Restore to normal state
	pass

# ─── Query API ───────────────────────────────────────────────────────────────

func is_anomalous() -> bool:
	return _is_anomalous
