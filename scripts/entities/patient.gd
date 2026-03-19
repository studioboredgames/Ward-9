extends CharacterBody3D
## patient.gd
## Responsibility: Authority for rendered truth of the patient (visuals).
## Detectable, subtle, and uncomfortable anomalies.

var is_anomalous: bool = false
var anomaly_type: String = ""

@onready var mesh: Node3D = get_node_or_null("MeshInstance3D")
var _breath_tween: Tween

# ─── Lifecycle ────────────────────────────────────────────────────────────────

func _ready() -> void:
	add_to_group("patient")
	# Interaction Layer (3)
	collision_layer = 4 


# ─── Anomaly Control ──────────────────────────────────────────────────────────

func apply_anomaly(type: String) -> void:
	# First clear any existing to ensure clean state
	clear_anomaly()
	
	is_anomalous = true
	anomaly_type = type

	if not mesh: return

	match type:
		"tilt":
			mesh.rotation_degrees.z = 25.0
		"breath":
			_start_breathing()
		"shift":
			mesh.position.x += 0.3


func clear_anomaly() -> void:
	is_anomalous = false
	anomaly_type = ""

	if _breath_tween:
		_breath_tween.kill()
		_breath_tween = null

	if mesh:
		mesh.rotation = Vector3.ZERO
		mesh.position = Vector3.ZERO
		mesh.scale = Vector3.ONE


# ─── Internal Animations ──────────────────────────────────────────────────────

func _start_breathing() -> void:
	if not mesh: return
	_breath_tween = create_tween().set_loops().set_trans(Tween.TRANS_SINE)
	_breath_tween.tween_property(mesh, "scale", Vector3(1.08, 1.08, 1.08), 1.2)
	_breath_tween.tween_property(mesh, "scale", Vector3.ONE, 1.2)


# ─── Contract for Evaluation ──────────────────────────────────────────────────

func has_visible_anomaly() -> bool:
	return is_anomalous
